import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/vehicle_repository.dart';

class VehicleViewModel extends ChangeNotifier {
  final VehicleRepository _vehicleRepository = VehicleRepository();

  Stream<QuerySnapshot> getVehiclesStream(String houseId) {
    return _vehicleRepository.getVehiclesStream(houseId);
  }

  Future<void> addVehicle(String houseId, Map<String, dynamic> data) {
    return _vehicleRepository.addVehicle(houseId, data);
  }

  Future<void> updateVehicle(String houseId, String vehicleId, Map<String, dynamic> data) {
    return _vehicleRepository.updateVehicle(houseId, vehicleId, data);
  }

  Future<void> deleteVehicle(String houseId, String vehicleId) {
    return _vehicleRepository.deleteVehicle(houseId, vehicleId);
  }
}
