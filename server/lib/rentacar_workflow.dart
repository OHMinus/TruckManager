import 'package:truck_manager/services/line.dart';
import 'package:truck_manager/services/mail.dart';
import 'package:truck_manager/services/asset_loader.dart';
import 'package:truck_manager/services/notify.dart';

class RentACarWorkflow {
  final GmailService _gmail;
  final LineNotifyService _line;

  RentACarWorkflow(this._gmail, this._line);

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
      final targetUserId = await AssetLoader.readAsset('LINE_TARGET_USER_ID');

      for (final messageMeta in messages) {
        final message = await _gmail.getMessageDetails(messageMeta.id!);
        final body = _gmail.getPlainTextBody(message);

        if (body != null) {
          final parsedData = _parseEmailBody(body);
          if (parsedData.isNotEmpty) {
            final flexContents = _createFlexMessageContents(parsedData);
            await _line.sendFlexMessage(
              to: targetUserId,
              altText: "レンタカー予約のお知らせ",
              contents: flexContents,
            );

            // Mark as read if not in debug mode
            if (!(await AssetLoader.isDebug())) {
              await _gmail.markAsRead(message.id!);
              print('Marked email ${message.id} as read.');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      print('An error occurred during the rent-a-car workflow: $e');
      print(stackTrace);
      await GASNotifyService.notifyErrorToGas(
          'Critical error in rent-a-car workflow: $e');
    }
  }

  Map<String, String> _parseEmailBody(String body) {
    final Map<String, String> result = {};

    // Determine status based on subject or body contents
    String status = "予約完了";
    if (body.contains("変更いたしました")) {
      status = "予約変更";
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

  Map<String, dynamic> _createFlexMessageContents(Map<String, String> data) {
    List<Map<String, dynamic>> boxContents = [];

    data.forEach((key, value) {
      if (key == 'ステータス') return; // Skip status in the body
      boxContents.add({
        "type": "box",
        "layout": "horizontal",
        "contents": [
          {
            "type": "text",
            "text": key,
            "size": "sm",
            "color": "#aaaaaa",
            "flex": 1
          },
          {
            "type": "text",
            "text": value,
            "size": "sm",
            "color": "#666666",
            "flex": 3,
            "wrap": true
          }
        ],
        "spacing": "sm"
      });
    });

    final isChanged = data['ステータス'] == '予約変更';
    final headerColor = isChanged ? "#ffc107" : "#0D8186";

    return {
      "type": "bubble",
      "size": "mega",
      "header": {
        "type": "box",
        "layout": "vertical",
        "contents": [
          {
            "type": "text",
            "text": data['ステータス'] ?? "レンタカー予約",
            "color": "#ffffff",
            "weight": "bold",
            "size": "md"
          }
        ],
        "backgroundColor": headerColor,
        "paddingAll": "12px"
      },
      "body": {
        "type": "box",
        "layout": "vertical",
        "contents": boxContents,
        "spacing": "md",
        "paddingAll": "12px"
      }
    };
  }
}
