import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/capsules.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderCapsule>> getOrdersStream() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return OrderCapsule.fromJson(data);
      }).toList();
    });
  }

  Future<OrderCapsule?> getOrderById(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (!data.containsKey('id')) {
        data['id'] = doc.id;
      }
      return OrderCapsule.fromJson(data);
    }
    return null;
  }
}
