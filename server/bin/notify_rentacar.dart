import 'package:truck_manager/services/line.dart';
import 'package:truck_manager/services/mail.dart';
import 'package:truck_manager/rentacar_workflow.dart';

Future<void> main() async {
  print('Starting Rent-a-car notification endpoint...');
  try {
    final lineService = await LineNotifyService.create();
    final gmailService = GmailServiceImpl();
    await gmailService.initialize();

    final workflow = RentACarWorkflow(gmailService, lineService);
    await workflow.run();
    print('Rent-a-car notification endpoint finished successfully.');
  } catch (e, stackTrace) {
    print('Critical error in Rent-a-car notification endpoint: $e');
    print(stackTrace);
  }
}
