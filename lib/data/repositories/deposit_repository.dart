import 'package:cloud_firestore/cloud_firestore.dart';

class DepositRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<QuerySnapshot> getActiveDeposit(String houseId, String roomId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('deposits')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'Active')
        .get();
  }

  Future<void> updateDeposit(String houseId, String depositId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('deposits')
        .doc(depositId)
        .update(data);
  }

  Future<void> submitDeposit(
    String houseId, 
    String roomId, 
    Map<String, dynamic> depositData, 
    Map<String, dynamic> transactionData,
    double depositAmount
  ) async {
    final batch = _firestore.batch();
    
    // Deposit
    final depositRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('deposits')
        .doc();
    batch.set(depositRef, depositData);

    // Update Room
    final roomRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId);
    batch.update(roomRef, {
      'status': 'Đang cọc giữ chỗ',
      'depositAmount': depositAmount,
    });

    // Transaction
    final transactionRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('transactions')
        .doc();
    batch.set(transactionRef, transactionData);

    await batch.commit();
  }

  Future<void> cancelDeposit(String houseId, String roomId, String depositId) async {
    final batch = _firestore.batch();
    
    // Update Deposit
    final depositRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('deposits')
        .doc(depositId);
    batch.update(depositRef, {
      'status': 'Canceled',
      'canceledAt': FieldValue.serverTimestamp()
    });

    // Update Room
    final roomRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rooms')
        .doc(roomId);
    batch.update(roomRef, {
      'status': 'Đang trống',
      'depositAmount': FieldValue.delete()
    });

    await batch.commit();
  }
}
