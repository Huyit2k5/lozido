import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../contracts/contract_provider.dart';

class ManageAssetsPage extends StatefulWidget {
  final String houseId;
  
  const ManageAssetsPage({super.key, required this.houseId});

  @override
  State<ManageAssetsPage> createState() => _ManageAssetsPageState();
}

class _ManageAssetsPageState extends State<ManageAssetsPage> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  // KHO: Mapping from asset ID -> Data (including availableQuantity)
  List<Map<String, dynamic>> _globalAssets = [];
  bool _isLoading = true;

  // Track the quantities selected by the user for this contract
  // Key: assetId, Value: quantity selected
  Map<String, int> _selectedQuantities = {};

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

      final List<Map<String, dynamic>> loaded = [];
      
      for (var doc in assetsQs.docs) {
        final data = doc.data();
        final aId = doc.id;
        
        // Calculate used quantity
        int usedQty = 0;
        for (var cDoc in contractsQs.docs) {
          final cData = cDoc.data();
          final cAssets = cData['assets'] as List?;
          if (cAssets != null) {
            for (var ca in cAssets) {
              if (ca != null) {
                if (ca['assetId'] == aId || ca['assetName'] == data['assetName']) {
                  usedQty += ((ca['quantity'] ?? 1) as num).toInt();
                }
              }
            }
          }
        }
        
        final totalQty = (data['quantity'] ?? 1).toInt();
        final availableQty = totalQty - usedQty;
        
        data['id'] = aId;
        data['availableQuantity'] = availableQty < 0 ? 0 : availableQty;
        data['totalQuantity'] = totalQty;
        loaded.add(data);
      }

      // 3. Pre-fill selections from Provider
      final currentContractAssets = Provider.of<ContractProvider>(context, listen: false).assets;
      final Map<String, int> initialSelections = {};
      
      for (var cAsset in currentContractAssets) {
        // Try to match by ID or Name
        final match = loaded.firstWhere(
          (a) => a['id'] == cAsset.assetId || a['assetName'] == cAsset.assetName, 
          orElse: () => <String, dynamic>{}
        );
        if (match.isNotEmpty) {
          initialSelections[match['id']] = cAsset.quantity;
          // If this asset was already allocated in THIS VERY CONTRACT, the formula `total - active_contracts` 
          // above actually deducted it! Meaning availableQuantity is lower than it should be if we are editing.
          // For simplicity, we just add the currently selected amount back to the virtual available pool 
          // so the user can re-adjust properly in this session.
          match['availableQuantity'] = (match['availableQuantity'] as int) + cAsset.quantity;
        }
      }

      _globalAssets = loaded;
      _selectedQuantities = initialSelections;

    } catch (e) {
      debugPrint("Error fetching inventory: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddAssetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAssetForm(
        onAdd: (assetData) async {
          try {
            await FirebaseFirestore.instance
                .collection('houses')
                .doc(widget.houseId)
                .collection('assets')
                .add({
              ...assetData,
              'createdAt': FieldValue.serverTimestamp(),
            });
            _fetchInventory(); // Reload to get the new asset into the list
          } catch (e) {
            debugPrint("Error creating asset: $e");
          }
        },
      ),
    );
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
        title: const Text(
          "Chọn tài sản cho phòng",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _showAddAssetModal,
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            tooltip: "Nhập tài sản mới vào kho",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _globalAssets.isEmpty
              ? Center(
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
                        onPressed: _showAddAssetModal,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Tạo tài sản vào kho", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _globalAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _globalAssets[index];
                    final aId = asset['id'] as String;
                    final available = asset['availableQuantity'] as int;
                    final total = asset['totalQuantity'] as int;
                    
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
                                  Text(asset['assetName'] ?? 'Tài sản', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('${_currencyFormat.format(asset['value'] ?? 0)} đ', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('Sẵn sàng: $available / $total', style: TextStyle(color: available > 0 ? Colors.black54 : Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            // Selection Control
                            if (available > 0 || currentSelectedQty > 0)
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
                                    icon: Icon(Icons.add_circle, color: currentSelectedQty < available ? const Color(0xFF00A651) : Colors.grey),
                                    onPressed: currentSelectedQty < available 
                                        ? () {
                                            setState(() {
                                              _selectedQuantities[aId] = currentSelectedQty + 1;
                                            });
                                          }
                                        : null, // Disable if reached max available
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
                  onPressed: () {
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
                          status: asset['status'] ?? 'Bình thường',
                        ));
                      }
                    }
                    Provider.of<ContractProvider>(context, listen: false).updateAssets(selectedAssets);
                    Navigator.pop(context);
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
}

// ---------------------------------------------------------
// ADD ASSET FORM 
// ---------------------------------------------------------

class _AddAssetForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddAssetForm({required this.onAdd});

  @override
  State<_AddAssetForm> createState() => _AddAssetFormState();
}

class _AddAssetFormState extends State<_AddAssetForm> {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Thêm mới vào Kho tổng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                IconButton(icon: const Icon(Icons.close, color: Colors.black54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField("Tên tài sản (*)", _nameCtrl),
            const SizedBox(height: 16),
            const Text("Chọn biểu tượng", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
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
            const SizedBox(height: 16),
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
                Expanded(child: _buildTextField("Số lượng nhập (*)", _quantityCtrl, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Đơn vị", _unitCtrl, hint: "Cái/Chiếc")),
              ],
            ),
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
                  final assetData = {
                    'assetName': _nameCtrl.text,
                    'iconTag': _selectedIcon,
                    'value': double.tryParse(_valueCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                    'importPrice': double.tryParse(_importPriceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                    'quantity': int.tryParse(_quantityCtrl.text) ?? 1,
                    'supplier': _supplierCtrl.text,
                    'unit': _unitCtrl.text.isNotEmpty ? _unitCtrl.text : 'Cái',
                    'status': _selectedStatus,
                  };
                  widget.onAdd(assetData);
                  Navigator.pop(context);
                },
                child: const Text("Tạo kiện tài sản", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
