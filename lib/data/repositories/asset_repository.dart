import 'package:cloud_firestore/cloud_firestore.dart';

class AssetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<QuerySnapshot> getAssets(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('assets')
        .get();
  }

  Future<void> addAsset(String houseId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('assets')
        .add(data);
  }

  Future<void> updateAsset(String houseId, String assetId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('assets')
        .doc(assetId)
        .update(data);
  }

  Future<void> deleteAsset(String houseId, String assetId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('assets')
        .doc(assetId)
        .delete();
  }
}
