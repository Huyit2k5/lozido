import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/asset_repository.dart';

class AssetViewModel extends ChangeNotifier {
  final AssetRepository _assetRepository = AssetRepository();

  Future<QuerySnapshot> getAssets(String houseId) {
    return _assetRepository.getAssets(houseId);
  }

  Future<void> addAsset(String houseId, Map<String, dynamic> data) {
    return _assetRepository.addAsset(houseId, data);
  }

  Future<void> updateAsset(String houseId, String assetId, Map<String, dynamic> data) {
    return _assetRepository.updateAsset(houseId, assetId, data);
  }

  Future<void> deleteAsset(String houseId, String assetId) {
    return _assetRepository.deleteAsset(houseId, assetId);
  }
}
