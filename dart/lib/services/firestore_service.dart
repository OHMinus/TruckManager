import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/capsules.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'truck',
  );

  Stream<List<OrderCapsule>> getOrdersStream() {
    try {
      return _firestore.collection('orders').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          return OrderCapsule.fromJson(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      print('🔥 Firestore Stream Error: $e');
      return Stream.value([]);
    }
  }

  Future<Map<String,dynamic>?> getOrderById(String id) async {
    try {
      final doc = await _firestore.collection('orders').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return data;
      }
    } catch (e, stackTrace) {
      print('🔥 Firestore GetOrder Error: $e');
    }
    return null;
  }

  Future<OrderCapsule?> getOrderCapById(String id) async {
    return getOrderById(id).then((data) {
      if (data != null) {
        return OrderCapsule.fromJson(data);
      }
      return null;
    });
  }
}