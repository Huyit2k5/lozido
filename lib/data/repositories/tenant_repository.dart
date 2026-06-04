import 'package:cloud_firestore/cloud_firestore.dart';

class TenantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTenantByUidStream(String uid) {
    return _firestore
        .collection('tenants')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot> getMemberStream(String houseId, String roomId, String uid) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot> getMembersStream(String houseId, String roomId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .snapshots();
  }
}
