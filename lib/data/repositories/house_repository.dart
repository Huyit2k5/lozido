import 'package:cloud_firestore/cloud_firestore.dart';

class HouseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getHousesStream(String userId) {
    return _firestore
        .collection('houses')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<DocumentSnapshot> getHouseStream(String houseId) {
    return _firestore.collection('houses').doc(houseId).snapshots();
  }

  Stream<QuerySnapshot> getRoomsStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .snapshots();
  }

  Stream<QuerySnapshot> getRoomsStreamOrdered(String houseId, {bool descending = false}) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .orderBy('createdAt', descending: descending)
        .snapshots();
  }

  Stream<DocumentSnapshot> getRoomDetailsStream(String houseId, String roomId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId)
        .snapshots();
  }

  Future<void> updateRoom(String houseId, String roomId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId)
        .update(data);
  }

  Future<DocumentSnapshot> getRoom(String houseId, String roomId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId)
        .get();
  }

  Future<QuerySnapshot> getRooms(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .get();
  }
}
