import 'dart:math';
import 'package:truck_manager/services/asset_loader.dart';
import 'package:truck_manager/services/firebase_service.dart';
import 'package:truck_manager/services/firestore_service.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:truck_manager/services/notify.dart';
import 'package:truck_manager/services/capsules.dart';

class UserService {
  final FirestoreService _firestoreService;

  UserService(this._firestoreService);

  static Future<UserService> Create() async {
    final collectionId = await AssetLoader.readAsset("FIRESTORE_DB_NAME");
    final firestore = await FirestoreService.create(collectionId);
    return UserService(firestore);
  }

  Future<UserCapsule> GetUser(String? mail) async {
    String color = "333333";
    if (mail == null) {
      return UserCapsule(
        address: "",
        color: color,
        name: "",
      );
    }
    var username = "";
    //Where mail = $mail
    //https://pub.dev/documentation/googleapis/latest/firestore/v1/FieldFilter-class.html (公式)
    final filter = Filter(
      fieldFilter: FieldFilter(
        field: FieldReference(fieldPath: 'address'),
        op: 'EQUAL',
        value: Value(stringValue: mail),
      ),
    );
    try {
      final docs = await _firestoreService.queryDocuments(
          collectionId: "user", filter: filter);
      if (docs.isNotEmpty) {
        final firstDoc = docs.first;
        username = firstDoc['name'] as String;
        color = firstDoc['color'] as String;
      } else {
        final defaultDoc = await _firestoreService.getDocument(
          collectionId: "user",
          docId: "default",
        );
        if (defaultDoc != null) {
          color = defaultDoc['color'] as String;
          username = "dafault";
        }
      }
    } catch (e, stackTrace) {
      GASNotifyService.notifyErrorToGas("faital error : $e \n $stackTrace");
    }
    return UserCapsule(
      address: mail,
      color: color,
      name: username,
    );
  }

}
