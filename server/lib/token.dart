import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:truck_manager/services/asset_loader.dart';

void main() async {
  final clientId = await AssetLoader.readAsset("OAUTH_ID");
  final clientSecret = await AssetLoader.readAsset("OAUTH_SECRET");

  final id = ClientId(clientId, clientSecret);

  // 必要な権限 (Gmail, Drive, Sheets, Datastoreなど)
  final scopes = [
    'https://www.googleapis.com/auth/gmail.modify',
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/datastore"
  ];

  try {
    // clientViaUserConsentManual ではなく clientViaUserConsent を使用
    // これによりバックグラウンドで一時的なローカルサーバー（localhost）が立ち上がります
    final client = await clientViaUserConsent(id, scopes, (url) {
      print('\n1. 以下の URL をブラウザで開いて認証してください:');
      print('------------------------------------------------------------');
      print(url);
      print('------------------------------------------------------------\n');
      print('2. アカウントを選択し、アクセスを許可してください。');
      print('※ 認証完了後、ターミナルに自動で結果が表示されます。');
    });

    // 取得したリフレッシュトークンを表示
    print('\n============================================================');
    print('【成功】リフレッシュトークンを取得しました！');
    print('これを .env や GitHub Secrets (G_REFRESH_TOKEN) に保存してください:');
    print('');
    print(client.credentials.refreshToken);
    print('============================================================');

    client.close();
    exit(0);
  } catch (e) {
    print('\nエラーが発生しました: $e');
    exit(1);
  }
}