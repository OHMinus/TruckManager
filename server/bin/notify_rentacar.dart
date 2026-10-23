import 'package:truck_manager/services/line.dart';
import 'package:truck_manager/services/mail.dart';
import 'package:truck_manager/rentacar_workflow.dart';
import 'package:truck_manager/services/firestore_service.dart';
import 'package:truck_manager/services/asset_loader.dart';
import 'package:truck_manager/services/spread_sheet.dart';

Future<void> main() async {
  print('Starting Rent-a-car notification endpoint...');
  try {
    final lineService = await LineNotifyService.create();
    final gmailService = GmailServiceImpl();
    await gmailService.initialize();
    String collection = await AssetLoader.readAsset('FIRESTORE_DB_NAME');
    final firestoreService = await FirestoreService.create(collection);
    final spreadsheet = await SpreadSheetService.create();

    final workflow = RentACarWorkflow(gmailService, lineService, firestoreService, spreadsheet);
    await workflow.run();
    print('Rent-a-car notification endpoint finished successfully.');
  } catch (e, stackTrace) {
    print('Critical error in Rent-a-car notification endpoint: $e');
    print(stackTrace);
  }
}
