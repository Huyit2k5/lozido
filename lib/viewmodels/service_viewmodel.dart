import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/service_repository.dart';

class ServiceViewModel extends ChangeNotifier {
  final ServiceRepository _serviceRepository = ServiceRepository();

  Stream<QuerySnapshot> getServicesStream(String houseId) {
    return _serviceRepository.getServicesStream(houseId);
  }

  Future<void> addService(String houseId, Map<String, dynamic> data) {
    return _serviceRepository.addService(houseId, data);
  }

  Future<void> deleteService(String houseId, String serviceId) {
    return _serviceRepository.deleteService(houseId, serviceId);
  }

  Future<void> ensureDefaultServices(String houseId, List<String> allRoomIds) {
    return _serviceRepository.ensureDefaultServices(houseId, allRoomIds);
  }
}
