import 'package:cloud_firestore/cloud_firestore.dart';

class ContractRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getContractsStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts')
        .snapshots();
  }

  Stream<QuerySnapshot> getFilteredContractsStream(String houseId, {dynamic floor, String? roomId, String? status}) {
    Query query = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts');

    if (floor != 'Tất cả' && floor != null && roomId == null) {
      query = query.where('floor', isEqualTo: floor);
    }
    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }
    if (status != null && status != 'Tất cả') {
      String dbStatus = status == 'Còn hạn' ? 'Active' : status;
      query = query.where('status', isEqualTo: dbStatus);
    } else {
      if (roomId == null) {
        query = query.where('status', isEqualTo: 'Active');
      }
    }

    return query.snapshots();
  }

  Future<QuerySnapshot> getContracts(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts')
        .get();
  }

  Future<QuerySnapshot> getActiveContracts(String houseId, String roomId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'Active')
        .get();
  }

  Stream<QuerySnapshot> getActiveContractsStream(String houseId, String roomId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'Active')
        .snapshots();
  }

  Future<void> updateContract(String houseId, String contractId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts')
        .doc(contractId)
        .update(data);
  }

  Future<DocumentReference> addContract(String houseId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('contracts')
        .add(data);
  }
}
