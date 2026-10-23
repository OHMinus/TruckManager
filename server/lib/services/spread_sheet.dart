import 'dart:convert';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:truck_manager/services/asset_loader.dart';
import 'package:truck_manager/services/capsules.dart';

class SpreadSheetService {
  SheetsApi? sheetsApi;

  String spreadsheetId;

  SpreadSheetService._(this.sheetsApi, this.spreadsheetId);

  static Future<SpreadSheetService> create() async {
    final spreadsheetIdTmp = await AssetLoader.readAsset("SHIFT_SHEET_ID");
    String serviceAccountJson;
    if (await AssetLoader.isDebug()) {
      serviceAccountJson =
          await AssetLoader.readAsset('./test/test_env/cnfg/g_cred.json');
    } else {
      serviceAccountJson = await AssetLoader.readAsset('GOOGLE_SERVICE_CRED');
    }
    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    // スプレッドシート読み書き用のスコープを指定
    final scopes = [SheetsApi.spreadsheetsScope];
    final authClient = await clientViaServiceAccount(credentials, scopes);

    final sheetsApiTmp = SheetsApi(authClient);

    return SpreadSheetService._(sheetsApiTmp, spreadsheetIdTmp);
  }

  Future<ShiftCapsule?> retriveTruckData(DateTime date) async {
    if (sheetsApi == null) throw Exception('APIが初期化されていません。');

    ShiftCapsule? shift;

    //日調君の範囲指定 (シート名がyyyymmの0埋めなし)
    final range = '${date.year}${date.month}!A:I';

    final targetDateStr = '${date.year}/${date.month}/${date.day}';
    try {
      final response =
          await sheetsApi!.spreadsheets.values.get(spreadsheetId, range);
      final rows = response.values;

      if (rows == null || rows.isEmpty) {
        print('シート"${date.year}${date.month}"がありません。');
        return ShiftCapsule();
      }

      // 3. ループで探索

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // A列(インデックス0)に日付が入っていると仮定
        final cellDateStr = row[0].toString();

        if (cellDateStr == targetDateStr) {
          shift = ShiftCapsule();
          shift.date = "${date.year}/${date.month}/${date.day}";
          shift.assignment = row.length > 8 ? row[8].toString() : '';
          shift.reserver = row.length > 7 ? row[7].toString() : '';
          shift.eventName = row.length > 2 ? row[2].toString() : '';
        }
      }

      if (shift == null) {
        print('$targetDateStr のデータは存在しませんでした。');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }

    return shift;
  }

  /// 日付とヘッダー項目名を指定して、対象セルの値を更新するメソッド
  Future<void> updateTruckDataByHeader(DateTime date, String headerName, String newValue) async {
    if (sheetsApi == null) throw Exception('APIが初期化されていません。');

    final sheetName = '${date.year}${date.month}';
    
    final searchRange = '$sheetName!A:Q'; 
    final targetDateStr = '${date.year}/${date.month}/${date.day}';

    try {
      final response = await sheetsApi!.spreadsheets.values.get(spreadsheetId, searchRange);
      final rows = response.values;

      if (rows == null || rows.isEmpty) {
        print('シート"$sheetName"がありません、または空です。');
        return;
      }

      // ヘッダーから、更新対象の列インデックスを特定
      final headerRow = rows[0];
      int targetColumnIndex = -1;

      for (int i = 0; i < headerRow.length; i++) {
        if (headerRow[i].toString().trim() == headerName) {
          targetColumnIndex = i;
          break;
        }
      }

      if (targetColumnIndex == -1) {
        print('ヘッダー行に "$headerName" が見つかりませんでした。更新を中断します。');
        return;
      }

      // A列から、更新対象の日付の行番号を特定
      int targetRowNumber = -1;
      
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final cellDateStr = row[0].toString();
        if (cellDateStr == targetDateStr) {
          targetRowNumber = i + 1; 
          break;
        }
      }

      if (targetRowNumber == -1) {
        print('$targetDateStr のデータは存在しませんでした。');
        return;
      }

      // APIへ送るためのA1表記とデータを準備して更新
      final colLetter = columnIndexToLetter(targetColumnIndex);
      final updateRange = '$sheetName!$colLetter$targetRowNumber'; // 例: 202610!I5

      final valueRange = ValueRange(
        values: [
          [newValue]
        ],
      );

      print('セル $updateRange (日付: $targetDateStr, 項目: $headerName) を更新中...');
      
      await sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        updateRange,
        valueInputOption: 'USER_ENTERED',
      );
      
      print('更新が完了しました。');

    } catch (e, stackTrace) {
      print('エラーが発生しました: $e \n $stackTrace');
    }
  }
  
  /// インデックスからアルファベットへの変換関数
  String columnIndexToLetter(int index) {
    int temp = index;
    String letter = '';
    while (temp >= 0) {
      letter = String.fromCharCode((temp % 26) + 'A'.codeUnitAt(0)) + letter;
      temp = (temp ~/ 26) - 1;
    }
    return letter;
  }
}
