import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/tenant_repository.dart';

class TenantViewModel extends ChangeNotifier {
  final TenantRepository _tenantRepository = TenantRepository();

  Stream<QuerySnapshot> getTenantByUidStream(String uid) {
    return _tenantRepository.getTenantByUidStream(uid);
  }

  Stream<QuerySnapshot> getMemberStream(String houseId, String roomId, String uid) {
    return _tenantRepository.getMemberStream(houseId, roomId, uid);
  }

  Stream<QuerySnapshot> getMembersStream(String houseId, String roomId) {
    return _tenantRepository.getMembersStream(houseId, roomId);
  }
}
