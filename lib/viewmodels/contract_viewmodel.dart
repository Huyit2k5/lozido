import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/contract_repository.dart';

class ContractViewModel extends ChangeNotifier {
  final ContractRepository _contractRepository = ContractRepository();

  Stream<QuerySnapshot> getContractsStream(String houseId) {
    return _contractRepository.getContractsStream(houseId);
  }

  Stream<QuerySnapshot> getFilteredContractsStream(String houseId, {dynamic floor, String? roomId, String? status}) {
    return _contractRepository.getFilteredContractsStream(houseId, floor: floor, roomId: roomId, status: status);
  }

  Future<QuerySnapshot> getContracts(String houseId) {
    return _contractRepository.getContracts(houseId);
  }

  Future<QuerySnapshot> getActiveContracts(String houseId, String roomId) {
    return _contractRepository.getActiveContracts(houseId, roomId);
  }

  Stream<QuerySnapshot> getActiveContractsStream(String houseId, String roomId) {
    return _contractRepository.getActiveContractsStream(houseId, roomId);
  }

  Future<void> updateContract(String houseId, String contractId, Map<String, dynamic> data) {
    return _contractRepository.updateContract(houseId, contractId, data);
  }

  Future<DocumentReference> addContract(String houseId, Map<String, dynamic> data) {
    return _contractRepository.addContract(houseId, data);
  }

  Future<void> endContract(String houseId, String contractId) {
    return _contractRepository.updateContract(houseId, contractId, {
      'status': 'Đã kết thúc',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}
