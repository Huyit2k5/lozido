import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lozido_app/presentation/widgets/app_dialog.dart';
import '../contracts/contract_provider.dart';

class ManageAssetsPage extends StatefulWidget {
  final String houseId;
  final String? roomId;
  final String? roomName;
  
  const ManageAssetsPage({
    super.key, 
    required this.houseId,
    this.roomId,
    this.roomName,
  });

  @override
  State<ManageAssetsPage> createState() => _ManageAssetsPageState();
}

class _ManageAssetsPageState extends State<ManageAssetsPage> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  // KHO: Mapping from asset ID -> Data (including availableQuantity)
  List<Map<String, dynamic>> _globalAssets = [];
  bool _isLoading = true;

  // Track the quantities selected by the user for this session
  Map<String, int> _selectedQuantities = {};
  
  bool _isWarehouseTab = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Assets
      final assetsQs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('assets')
          .get();
          
      // 2. Fetch Active Contracts to calculate usage
      final contractsQs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .where('status', isNotEqualTo: 'Đã kết thúc')
          .get();

      final List<Map<String, dynamic>> loadedAssetDocs = [];
      for (var doc in assetsQs.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        loadedAssetDocs.add(data);
      }

      // 3. Determine current assets for this room (if any)
      List<dynamic> currentRoomAssets = [];
      if (widget.roomId != null) {
        // Find contract for this room
        final roomContract = contractsQs.docs.cast<DocumentSnapshot?>().firstWhere(
          (c) => c != null && (c.data() as Map<String, dynamic>)['roomId'] == widget.roomId,
          orElse: () => null
        );
        if (roomContract != null) {
          currentRoomAssets = (roomContract.data() as Map<String, dynamic>)['assets'] as List? ?? [];
        }
      } else {
        // Creation flow: Get from Provider
        final providerAssets = Provider.of<ContractProvider>(context, listen: false).assets;
        currentRoomAssets = providerAssets.map((a) => a.toMap()).toList();
      }

      // 4. Calculate Inventory availableQuantity
      final List<Map<String, dynamic>> finalAssets = [];
      final Map<String, int> initialSelections = {};

      for (var asset in loadedAssetDocs) {
        final aId = asset['id'];
        
        // Calculate global usage EXCEPT for this room (because we want to re-adjust this room's portion)
        int usedByOthers = 0;
        for (var cDoc in contractsQs.docs) {
          final cData = cDoc.data() as Map<String, dynamic>;
          if (widget.roomId != null && cData['roomId'] == widget.roomId) continue; 
          
          final cAssets = cData['assets'] as List?;
          if (cAssets != null) {
            for (var ca in cAssets) {
              if (ca != null && (ca['assetId'] == aId || ca['assetName'] == asset['assetName'])) {
                usedByOthers += ((ca['quantity'] ?? 1) as num).toInt();
              }
            }
          }
        }

        // If not in direct room mode (e.g. creating new contract), we still deduct what's in provider? 
        // No, provider is the "tentative" selection for THE CURRENT session.
        // So `usedByOthers` is correct as "already committed to other rooms".

        final totalQty = (asset['quantity'] ?? 1).toInt();
        final breakdown = Map<String, dynamic>.from(asset['statusBreakdown'] ?? {});
        final goodQty = ((breakdown['Hoạt động tốt'] ?? (asset['status'] == 'Hoạt động tốt' ? totalQty : 0)) as num).toInt();

        final availableGoodToThisRoom = goodQty - usedByOthers;
        
        asset['availableGoodQuantity'] = availableGoodToThisRoom < 0 ? 0 : availableGoodToThisRoom;
        asset['totalQuantity'] = totalQty;
        asset['goodQuantity'] = goodQty;
        finalAssets.add(asset);

        // Check if this asset is currently in the room
        final inRoom = currentRoomAssets.cast<Map<String, dynamic>?>().firstWhere(
          (ra) => ra != null && (ra['assetId'] == aId || ra['assetName'] == asset['assetName']),
          orElse: () => null
        );
        if (inRoom != null) {
          initialSelections[aId] = (inRoom['quantity'] ?? 1).toInt();
        }
      }

      _globalAssets = finalAssets;
      _selectedQuantities = initialSelections;

    } catch (e) {
      debugPrint("Error fetching inventory: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _handleManualAdd(Map<String, dynamic> assetData) async {
    final name = assetData['assetName'].toString().trim();
    final requestedQty = assetData['quantity'] as int;
    final iconTag = assetData['iconTag'];

    // 1. Check for match in Warehouse
    final matchIndex = _globalAssets.indexWhere((a) => 
      a['assetName'].toString().trim().toLowerCase() == name.toLowerCase() &&
      a['iconTag'] == iconTag
    );

    if (matchIndex != -1) {
      final match = _globalAssets[matchIndex];
      final aId = match['id'];
      final available = (match['availableGoodQuantity'] ?? 0) as int;

      if (available >= requestedQty) {
        setState(() {
          _selectedQuantities[aId] = (_selectedQuantities[aId] ?? 0) + requestedQty;
          _isWarehouseTab = true; // Switch back to see result
        });
        AppDialog.show(context, title: "Đã khớp kho", message: "Tài sản '$name' đã có trong kho. Hệ thống đã tự động chọn từ kho và trừ số lượng.", type: AppDialogType.success);
      } else {
        AppDialog.show(context, title: "Hết hàng", message: "Tài sản '$name' có trong kho nhưng không đủ số lượng sẵn sàng (Sẵn sàng: $available).", type: AppDialogType.warning);
      }
    } else {
      // 2. New Asset - Create in Warehouse with quantity set to room allocation
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('assets')
            .add({
          ...assetData,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _fetchInventory(); // Refresh list to get new entry

        setState(() {
          _selectedQuantities[docRef.id] = requestedQty;
          _isWarehouseTab = true;
        });

        AppDialog.show(context, title: "Thành công", message: "Đã tạo mới tài sản '$name' vào kho và áp dụng cho phòng.", type: AppDialogType.success);
      } catch (e) {
        AppDialog.show(context, title: "Lỗi", message: "Không thể tạo tài sản mới: $e", type: AppDialogType.error);
      }
    }
  }

  IconData _getIconData(String? name) {
    if (name == null) return Icons.category;
    if (name.contains('Tủ lạnh')) return Icons.kitchen;
    if (name.contains('Máy giặt')) return Icons.local_laundry_service;
    if (name.contains('Điều hòa')) return Icons.ac_unit;
    if (name.contains('Giường')) return Icons.bed;
    if (name.contains('Bàn ghế')) return Icons.chair;
    if (name.contains('Tủ quần áo')) return Icons.checkroom;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.roomName != null ? "Cấp tài sản: ${widget.roomName}" : "Quản lý tài sản phòng",
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Custom TabBar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isWarehouseTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isWarehouseTab ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _isWarehouseTab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                        ),
                        child: Center(
                          child: Text(
                            "Chọn từ Kho",
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: _isWarehouseTab ? FontWeight.bold : FontWeight.normal,
                              color: _isWarehouseTab ? const Color(0xFF00A651) : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isWarehouseTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isWarehouseTab ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_isWarehouseTab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                        ),
                        child: Center(
                          child: Text(
                            "Nhập mới cho Phòng",
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: !_isWarehouseTab ? FontWeight.bold : FontWeight.normal,
                              color: !_isWarehouseTab ? const Color(0xFF00A651) : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isWarehouseTab 
              ? (_isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _globalAssets.isEmpty
                      ? _buildEmptyInventory()
                      : _buildWarehouseList())
              : _ManualAssetForm(
                  onAdd: _handleManualAdd,
                  onSwitchToWarehouse: () => setState(() => _isWarehouseTab = true),
                ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                    backgroundColor: const Color(0xFFF5F5F5),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final List<ContractAsset> selectedAssets = [];
                    for (var asset in _globalAssets) {
                      final aId = asset['id'] as String;
                      final qty = _selectedQuantities[aId] ?? 0;
                      if (qty > 0) {
                        selectedAssets.add(ContractAsset(
                          assetId: aId,
                          assetName: asset['assetName'] ?? '',
                          iconTag: asset['iconTag'] ?? 'category',
                          value: (asset['value'] ?? 0).toDouble(),
                          importPrice: (asset['importPrice'] ?? 0).toDouble(),
                          quantity: qty,
                          supplier: asset['supplier'] ?? '',
                          unit: asset['unit'] ?? 'Cái',
                          status: 'Hoạt động tốt',
                          statusBreakdown: {
                            'Hoạt động tốt': qty,
                            'Không hoạt động': 0,
                            'Hư hỏng nhẹ': 0,
                            'Đang sửa chữa': 0,
                          },
                        ));
                      }
                    }

                    if (widget.roomId != null) {
                      // Direct Firestore Mode
                      try {
                        setState(() => _isLoading = true);
                        final qs = await FirebaseFirestore.instance
                            .collection('houses')
                            .doc(widget.houseId)
                            .collection('contracts')
                            .where('roomId', isEqualTo: widget.roomId)
                            .where('status', isEqualTo: 'Active')
                            .get();
                        
                        if (qs.docs.isNotEmpty) {
                          final contractId = qs.docs.first.id;
                          await FirebaseFirestore.instance
                              .collection('houses')
                              .doc(widget.houseId)
                              .collection('contracts')
                              .doc(contractId)
                              .update({'assets': selectedAssets.map((a) => a.toMap()).toList()});
                          
                          if (mounted) {
                            AppDialog.show(context, title: "Thành công", message: "Đã cập nhật tài sản cho phòng thành công!", type: AppDialogType.success);
                            Navigator.pop(context, true); // Return true to signal refresh
                          }
                        } else {
                          if (mounted) {
                            AppDialog.show(context, title: "Không tìm thấy hợp đồng", message: "Không tìm thấy hợp đồng hoạt động cho phòng này", type: AppDialogType.warning);
                          }
                        }
                      } catch (e) {
                          debugPrint("Error updating assets: $e");
                          if (mounted) {
                            AppDialog.show(context, title: "Lỗi", message: "Lỗi hệ thống: $e", type: AppDialogType.error);
                          }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    } else {
                      // Provider Mode (Normal Flow)
                      Provider.of<ContractProvider>(context, listen: false).updateAssets(selectedAssets);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Áp dụng vào Phòng", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("Kho chưa có tài sản nào...", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => setState(() => _isWarehouseTab = false),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Nhập thủ công cho phòng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildWarehouseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _globalAssets.length,
      itemBuilder: (context, index) {
        final asset = _globalAssets[index];
        final aId = asset['id'] as String;
        final availableGood = (asset['availableGoodQuantity'] ?? 0) as int;
        final total = (asset['totalQuantity'] ?? 0) as int;
        
        final currentSelectedQty = _selectedQuantities[aId] ?? 0;
        final isSelected = currentSelectedQty > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade50 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconData(asset['iconTag']), color: isSelected ? const Color(0xFF00A651) : Colors.black87, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              asset['assetName'] ?? 'Tài sản',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(asset['status'] ?? 'Hoạt động tốt', asset['statusBreakdown']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${_currencyFormat.format(asset['value'] ?? 0)} đ', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Sẵn sàng (Tốt): ${asset['availableGoodQuantity']} / Tổng Tốt: ${asset['goodQuantity']}', 
                           style: TextStyle(color: (asset['availableGoodQuantity'] as int) > 0 ? Colors.black54 : Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Selection Control
                if (availableGood > 0 || currentSelectedQty > 0)
                  Row(
                    children: [
                      if (currentSelectedQty > 0) ...[
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedQuantities[aId] = currentSelectedQty - 1;
                            });
                          },
                        ),
                        Text('$currentSelectedQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                      IconButton(
                        icon: Icon(Icons.add_circle, color: currentSelectedQty < (asset['availableGoodQuantity'] as int) ? const Color(0xFF00A651) : Colors.grey),
                        onPressed: currentSelectedQty < (asset['availableGoodQuantity'] as int) 
                            ? () {
                                setState(() {
                                  _selectedQuantities[aId] = currentSelectedQty + 1;
                                });
                              }
                            : null, // Disable if reached max available GOOD
                      ),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Hết hàng', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, Map<dynamic, dynamic>? breakdown) {
    String displayStatus = status;
    if (breakdown != null && breakdown.isNotEmpty) {
      String dominant = status;
      int max = -1;
      breakdown.forEach((s, q) {
        if ((q as num).toInt() > max) {
          max = q.toInt();
          dominant = s.toString();
        }
      });
      displayStatus = dominant;
    }

    Color color;
    switch (displayStatus) {
      case 'Hoạt động tốt': color = const Color(0xFF00A651); break;
      case 'Hư hỏng nhẹ': color = Colors.orange; break;
      case 'Không hoạt động': color = Colors.grey; break;
      case 'Đang sửa chữa': color = Colors.blue; break;
      default: color = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(displayStatus, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ---------------------------------------------------------
// MANUAL ASSET FORM (Embedded in Tab)
// ---------------------------------------------------------

class _ManualAssetForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final VoidCallback onSwitchToWarehouse;

  const _ManualAssetForm({
    required this.onAdd,
    required this.onSwitchToWarehouse,
  });

  @override
  State<_ManualAssetForm> createState() => _ManualAssetFormState();
}

class _ManualAssetFormState extends State<_ManualAssetForm> {
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _importPriceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  String _selectedStatus = 'Hoạt động tốt';

  String _selectedIcon = 'Tủ lạnh';
  final List<String> _icons = ['Tủ lạnh', 'Máy giặt', 'Điều hòa', 'Giường', 'Tủ quần áo', 'Bàn ghế'];

  IconData _getIconData(String name) {
    switch (name) {
      case 'Tủ lạnh': return Icons.kitchen;
      case 'Máy giặt': return Icons.local_laundry_service;
      case 'Điều hòa': return Icons.ac_unit;
      case 'Giường': return Icons.bed;
      case 'Tủ quần áo': return Icons.checkroom;
      case 'Bàn ghế': return Icons.chair;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Chi tiết tài sản", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              TextButton.icon(
                onPressed: widget.onSwitchToWarehouse,
                icon: const Icon(Icons.search, size: 18, color: Color(0xFF00A651)),
                label: const Text("Chọn từ kho tổng", style: TextStyle(color: Color(0xFF00A651), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Nếu tài sản đã có trong kho, hệ thống sẽ tự động trừ từ kho.\nNếu chưa có, hệ thống sẽ thêm mới vào kho tổng.",
            style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          _buildTextField("Tên tài sản (*)", _nameCtrl),
          const SizedBox(height: 16),
          const Text("Chọn biểu tượng", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _icons.map((e) {
              final isSelected = _selectedIcon == e;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = e),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                    border: Border.all(color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIconData(e), color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade600, size: 24),
                      const SizedBox(height: 4),
                      Text(e, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFF00A651) : Colors.black87)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField("Giá trị", _valueCtrl, isNumber: true, hint: "VNĐ")),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Giá nhập", _importPriceCtrl, isNumber: true, hint: "VNĐ")),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Số lượng (*)", _quantityCtrl, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Đơn vị", _unitCtrl, hint: "Cái/Chiếc")),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          const Text("Trạng thái: Hoạt động tốt", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A651), fontSize: 13)),
          const Text("Tài sản cấp vào phòng phải ở trạng thái hoạt động tốt.", style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                if (_nameCtrl.text.isEmpty || _quantityCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên và số lượng")));
                  return;
                }
                final qty = int.tryParse(_quantityCtrl.text) ?? 1;
                final assetData = {
                  'assetName': _nameCtrl.text,
                  'iconTag': _selectedIcon,
                  'value': double.tryParse(_valueCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                  'importPrice': double.tryParse(_importPriceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                  'quantity': qty,
                  'supplier': _supplierCtrl.text,
                  'unit': _unitCtrl.text.isNotEmpty ? _unitCtrl.text : 'Cái',
                  'status': 'Hoạt động tốt',
                  'statusBreakdown': {
                    'Hoạt động tốt': qty,
                    'Không hoạt động': 0,
                    'Hư hỏng nhẹ': 0,
                    'Đang sửa chữa': 0,
                  },
                };
                widget.onAdd(assetData);
              },
              child: const Text("Xác nhận & Thêm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00A651))),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
