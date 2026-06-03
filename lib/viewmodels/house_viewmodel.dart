import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/house_repository.dart';

class HouseViewModel extends ChangeNotifier {
  final HouseRepository _houseRepository;

  HouseViewModel({HouseRepository? houseRepository})
      : _houseRepository = houseRepository ?? HouseRepository();

  Stream<QuerySnapshot> getHousesStream(String userId) {
    return _houseRepository.getHousesStream(userId);
  }

  Stream<DocumentSnapshot> getHouseStream(String houseId) {
    return _houseRepository.getHouseStream(houseId);
  }

  Stream<QuerySnapshot> getRoomsStream(String houseId) {
    return _houseRepository.getRoomsStream(houseId);
  }

  Stream<QuerySnapshot> getRoomsStreamOrdered(String houseId, {bool descending = false}) {
    return _houseRepository.getRoomsStreamOrdered(houseId, descending: descending);
  }

  Stream<DocumentSnapshot> getRoomDetailsStream(String houseId, String roomId) {
    return _houseRepository.getRoomDetailsStream(houseId, roomId);
  }

  Future<void> updateRoom(String houseId, String roomId, Map<String, dynamic> data) {
    return _houseRepository.updateRoom(houseId, roomId, data);
  }

  Future<DocumentSnapshot> getRoom(String houseId, String roomId) {
    return _houseRepository.getRoom(houseId, roomId);
  }

  Future<QuerySnapshot> getRooms(String houseId) {
    return _houseRepository.getRooms(houseId);
  }
}
