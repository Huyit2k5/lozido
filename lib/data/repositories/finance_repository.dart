import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTransactionsStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<DocumentReference> addTransaction(String houseId, Map<String, dynamic> transactionData) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('transactions')
        .add(transactionData);
  }
}
