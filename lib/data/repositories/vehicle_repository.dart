import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getVehiclesStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addVehicle(String houseId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('vehicles')
        .add(data);
  }

  Future<void> updateVehicle(String houseId, String vehicleId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('vehicles')
        .doc(vehicleId)
        .update(data);
  }

  Future<void> deleteVehicle(String houseId, String vehicleId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('vehicles')
        .doc(vehicleId)
        .delete();
  }
}
