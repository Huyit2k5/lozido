import 'package:flutter/material.dart';

class ContractAsset {
  final String? assetId;
  final String assetName;
  final String iconTag;
  final double value;
  final double importPrice;
  final int quantity;
  final String supplier;
  final String unit;
  final String status;
  final Map<String, int>? statusBreakdown;

  ContractAsset({
    this.assetId,
    required this.assetName,
    required this.iconTag,
    required this.value,
    required this.importPrice,
    required this.quantity,
    required this.supplier,
    required this.unit,
    required this.status,
    this.statusBreakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      if (assetId != null) 'assetId': assetId,
      'assetName': assetName,
      'iconTag': iconTag,
      'value': value,
      'importPrice': importPrice,
      'quantity': quantity,
      'supplier': supplier,
      'unit': unit,
      'status': status,
      if (statusBreakdown != null) 'statusBreakdown': statusBreakdown,
    };
  }
}

class ContractProvider extends ChangeNotifier {
  List<ContractAsset> _assets = [];

  List<ContractAsset> get assets => _assets;

  void updateAssets(List<ContractAsset> newAssets) {
    _assets = List.from(newAssets);
    notifyListeners();
  }
}
