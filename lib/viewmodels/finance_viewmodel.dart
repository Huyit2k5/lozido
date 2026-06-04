import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/finance_repository.dart';

class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepository = FinanceRepository();

  Stream<QuerySnapshot> getTransactionsStream(String houseId) {
    return _financeRepository.getTransactionsStream(houseId);
  }

  Future<DocumentReference> addTransaction(String houseId, Map<String, dynamic> transactionData) {
    return _financeRepository.addTransaction(houseId, transactionData);
  }
}
