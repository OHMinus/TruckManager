import 'package:truck_manager/services/line.dart';
import 'package:truck_manager/services/mail.dart';
import 'package:truck_manager/services/asset_loader.dart';
import 'package:truck_manager/services/notify.dart';
import 'package:truck_manager/services/firestore_service.dart';
import 'package:truck_manager/services/capsules.dart';
import 'package:truck_manager/services/color.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class RentACarWorkflow {
  final GmailService _gmail;
  final LineNotifyService _line;
  final FirestoreService _firestore;

  RentACarWorkflow(this._gmail, this._line, this._firestore);

  Future<void> run() async {
    print('Rent-a-car workflow started.');
    try {
      final messages =
          await _gmail.fetchMessageList('is:unread subject:("【ニッポンレンタカー】ご予約")');
      if (messages.isEmpty) {
        print('No new rent-a-car emails to process.');
        return;
      }

      print('Found ${messages.length} rent-a-car emails.');
      var orders = <OrderCapsule>[];
      for (final messageMeta in messages) {
        final message = await _gmail.getMessageDetails(messageMeta.id!);
        final body = _gmail.getPlainTextBody(message);
        if (body != null) {
          final parsedData = await _parseEmailBody(body);
          print("Send balloon to ${parsedData['予約番号']}");
          
          if (parsedData['予約番号'] != '不明') {
            var uuid = Uuid();
            parsedData['予約番号'] = uuid.v4().toString();
          }
          if (parsedData['出発日時'] == '不明' || parsedData["出発日時"] == null) {
            print('出発日時が不明のため、メール ${message.id} をスキップします。');
            continue;
          }else{
            DateTime date = DateFormat('yyyy/MM/dd HH:mm').parse(parsedData['出発日時']!);
            parsedData['出発日時'] = date.toIso8601String();
          }
          
          OrderCapsule order = OrderCapsule(
            state : State.reserved,
            date :  parsedData['出発日時'] ?? '',
            reserver: parsedData['お名前'] ?? '',
            lastUpdated : DateTime.now(),
            price : '不明',
            url : '',
            id : parsedData['予約番号'] ?? '',
          );

          order.percentage = "${order.getPercentageValue()}%";

          ColorService colService = await ColorService.Create();
          String? eMail = await _gmail.GetOriginalSender(message.id!);
          if (eMail != null) {
            eMail = eMail.split(" ")[0];
          }
          HSL color = await colService.GetColor(eMail);
          color.L = order.getIdealLightness();
          order.BGColor = color.ToRGBSt();

          // Save to Firestore
          String docId = parsedData['予約番号'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          if (docId == '不明') docId = DateTime.now().millisecondsSinceEpoch.toString();
          await _firestore.saveDocument(
            collectionId: "rentacar_bookings",
            docId: docId,
            data: {
              ...order.toJson(),
              "carType": parsedData['クラス'] ?? '',
              "pickupLocation": parsedData['出発店舗'] ?? '',
              "returnDate": parsedData['返却日時'] ?? '',
              "departureDate": parsedData['出発日時'] ?? '',  
            },
          );

          // Mark as read if not in debug mode
          if (!(await AssetLoader.isDebug())) {
            await _gmail.markAsRead(message.id!);
            print('Marked email ${message.id} as read.');
          }
          
          orders.add(order);
        }else{
          print('No plain text body found for email ${message.id}.');
        }
      }
      if (orders.isNotEmpty) {
        print('Sending LINE notifications for ${orders.length} orders.');
        await _line.sendOrderNotifications(orders, "レンタカー予約のお知らせ");
      } else {
        print('No valid orders to send notifications for.');
      }

    } catch (e, stackTrace) {
      print('An error occurred during the rent-a-car workflow: $e');
      print(stackTrace);
      await GASNotifyService.notifyErrorToGas(
          'Critical error in rent-a-car workflow: $e');
    }
  }

  Future<Map<String, String>> _parseEmailBody(String body) async{
    final Map<String, String> result = {};

    // Determine status based on subject or body contents
    String status = "予約完了";
    if (body.contains("変更いたしました")) {
      status = "予約変更";
    }

    body = body.replaceAll("\r\n", "\n"); // Normalize line endings
    if (await AssetLoader.isDebug()) {
      print(body);
    }

    result['ステータス'] = status;
    result['予約番号'] = _extractMatch(body, RegExp(r'予約番号：(.*?)\n'));
    result['お名前'] = _extractMatch(body, RegExp(r'お名前：(.*?)\n'));
    result['出発日時'] = _extractMatch(body, RegExp(r'出発日時：(.*?)\n'));
    result['返却日時'] = _extractMatch(body, RegExp(r'返却日時：(.*?)\n'));
    result['出発店舗'] = _extractMatch(body, RegExp(r'出発店舗\(TEL\)：(.*?)\n'));
    result['クラス'] = _extractMatch(body, RegExp(r'クラス：(.*?)\n'));

    return result;
  }

  String _extractMatch(String text, RegExp regex) {
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '不明';
  }
}
