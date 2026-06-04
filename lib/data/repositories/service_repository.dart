import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getServicesStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('services')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> addService(String houseId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('services')
        .add(data);
  }

  Future<void> deleteService(String houseId, String serviceId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  Future<void> ensureDefaultServices(String houseId, List<String> allRoomIds) async {
    final servicesRef = _firestore.collection('houses').doc(houseId).collection('services');
    final snapshot = await servicesRef.limit(1).get();

    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      
      batch.set(servicesRef.doc(), {
        'serviceName': 'Tiền điện',
        'price': 1700,
        'unit': 'KWh',
        'isMetered': true,
        'appliedRooms': allRoomIds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(servicesRef.doc(), {
        'serviceName': 'Tiền nước',
        'price': 18000,
        'unit': 'Khối',
        'isMetered': true,
        'appliedRooms': allRoomIds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }
}
