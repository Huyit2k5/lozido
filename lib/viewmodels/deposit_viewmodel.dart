import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/deposit_repository.dart';

class DepositViewModel extends ChangeNotifier {
  final DepositRepository _depositRepository = DepositRepository();

  Future<QuerySnapshot> getActiveDeposit(String houseId, String roomId) {
    return _depositRepository.getActiveDeposit(houseId, roomId);
  }

  Future<void> updateDeposit(String houseId, String depositId, Map<String, dynamic> data) {
    return _depositRepository.updateDeposit(houseId, depositId, data);
  }

  Future<void> submitDeposit(
    String houseId, 
    String roomId, 
    Map<String, dynamic> depositData, 
    Map<String, dynamic> transactionData,
    double depositAmount
  ) {
    return _depositRepository.submitDeposit(houseId, roomId, depositData, transactionData, depositAmount);
  }

  Future<void> cancelDeposit(String houseId, String roomId, String depositId) {
    return _depositRepository.cancelDeposit(houseId, roomId, depositId);
  }
}
