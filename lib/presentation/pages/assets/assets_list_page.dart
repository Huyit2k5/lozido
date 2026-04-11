import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './manage_assets_page.dart';

class AssetListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const AssetListPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  String? _selectedRoomId;
  String _selectedStatus = 'Tất cả trạng thái';
  List<Map<String, dynamic>> _rooms = [];

  // Data
  List<Map<String, dynamic>> _globalAssets = [];
  List<Map<String, dynamic>> _activeContracts = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Rooms for dropdown
      final roomsQs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .get();
      _rooms = roomsQs.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      // 2. Fetch Assets (Global KHO)
      final assetsQs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('assets')
          .get();
      _globalAssets = assetsQs.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      // 3. Fetch Contracts to calculate usage
      final contractsQs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .get();
          
      _activeContracts = contractsQs.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).where((c) => c['status'] != 'Đã kết thúc').toList(); // Only active contracts use assets

    } catch (e) {
      debugPrint("Error fetching asset data: $e");
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
        onSave: (assetData) async {
          try {
            await FirebaseFirestore.instance
                .collection('houses')
                .doc(widget.houseId)
                .collection('assets')
                .add({
              ...assetData,
              'createdAt': FieldValue.serverTimestamp(),
            });
            _fetchData(); // Reload
          } catch (e) {
            debugPrint("Error adding asset: $e");
          }
        },
      ),
    );
  }

  void _showEditAssetModal(Map<String, dynamic> item) {
    int? maxAllowed;
    if (_selectedRoomId != null) {
      // Room View: Calculate available stock
      final assetId = item['assetId'];
      final assetName = item['assetName'];
      
      final master = _globalAssets.firstWhere(
        (a) => (assetId != null && a['id'] == assetId) || (a['assetName'] == assetName),
        orElse: () => {}
      );
      
      if (master.isNotEmpty) {
        int totalStock = (master['quantity'] ?? 0).toInt();
        int totalUsed = 0;
        for (var contract in _activeContracts) {
          final cAssets = contract['assets'] as List?;
          if (cAssets != null) {
            for (var ca in cAssets) {
              if ((assetId != null && ca['assetId'] == assetId) || (ca['assetName'] == assetName)) {
                totalUsed += ((ca['quantity'] ?? 1) as num).toInt();
              }
            }
          }
        }
        maxAllowed = (item['quantity'] ?? 0).toInt() + (totalStock - totalUsed);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAssetForm(
        initialData: item,
        maxAllowed: maxAllowed,
        onSave: (newData) => _updateAsset(item, newData),
      ),
    );
  }

  Future<void> _updateAsset(Map<String, dynamic> oldItem, Map<String, dynamic> newData) async {
    try {
      if (_selectedRoomId == null) {
        // Global Update
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('assets')
            .doc(oldItem['id'])
            .update(newData);
      } else {
        // Room Update (Contract Update)
        final contract = _activeContracts.firstWhere((c) => c['roomId'] == _selectedRoomId);
        final List<dynamic> assets = List.from(contract['assets'] ?? []);
        
        final index = assets.indexWhere((a) => a['assetName'] == oldItem['assetName'] && a['quantity'] == oldItem['quantity']);
        if (index != -1) {
          assets[index] = {
            ...assets[index],
            ...newData,
          };
          await FirebaseFirestore.instance
              .collection('houses')
              .doc(widget.houseId)
              .collection('contracts')
              .doc(contract['id'])
              .update({'assets': assets});
        }
      }
      _fetchData();
    } catch (e) {
      debugPrint("Error updating asset: $e");
    }
  }

  Future<void> _deleteAsset(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xoá"),
        content: Text("Bạn có chắc chắn muốn xoá ${item['assetName']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Huỷ")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xoá", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_selectedRoomId == null) {
        // Global Delete
        // Check if used
        bool isUsed = false;
        for (var contract in _activeContracts) {
          final cAssets = contract['assets'] as List?;
          if (cAssets != null) {
            if (cAssets.any((ca) => ca['assetId'] == item['id'] || ca['assetName'] == item['assetName'])) {
              isUsed = true;
              break;
            }
          }
        }

        if (isUsed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể xoá tài sản đang được sử dụng trong hợp đồng")));
          return;
        }

        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('assets')
            .doc(item['id'])
            .delete();
      } else {
        // Room Delete (Remove from contract)
        final contract = _activeContracts.firstWhere((c) => c['roomId'] == _selectedRoomId);
        final List<dynamic> assets = List.from(contract['assets'] ?? []);
        assets.removeWhere((a) => a['assetName'] == item['assetName'] && a['quantity'] == item['quantity']);
        
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(contract['id'])
            .update({'assets': assets});
      }
      _fetchData();
    } catch (e) {
      debugPrint("Error deleting asset: $e");
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

  // Generate dynamic list of assets to display
  List<Map<String, dynamic>> get _displayAssets {
    if (_selectedRoomId != null) {
      // Show ONLY assets inside the selected room (from its active contract)
      final roomContract = _activeContracts.cast<Map<String, dynamic>?>().firstWhere(
        (c) => c != null && c['roomId'] == _selectedRoomId, 
        orElse: () => null
      );
      
      if (roomContract == null || roomContract['assets'] == null) return [];
      
      List<Map<String, dynamic>> res = [];
      for (var a in (roomContract['assets'] as List)) {
        res.add(Map<String, dynamic>.from(a as Map));
      }

      // Filter by status if needed
      if (_selectedStatus != 'Tất cả trạng thái') {
        res = res.where((a) => a['status'] == _selectedStatus).toList();
      }
      return res;
    } else {
      // Show Global Inventory
      List<Map<String, dynamic>> res = [];
      for (var asset in _globalAssets) {
        final aId = asset['id'];
        
        // Calculate used quantity
        int usedQty = 0;
        for (var contract in _activeContracts) {
          final cAssets = contract['assets'] as List?;
          if (cAssets != null) {
            for (var ca in cAssets) {
              if (ca != null && ca['assetId'] == aId || ca['assetName'] == asset['assetName']) {
                // Warning: Fallback to assetName matching if ID is not available for older records
                usedQty += ((ca['quantity'] ?? 1) as num).toInt();
              }
            }
          }
        }
        
        final combined = Map<String, dynamic>.from(asset);
        combined['usedQuantity'] = usedQty;
        
        // Filter by status
        if (_selectedStatus == 'Tất cả trạng thái' || combined['status'] == _selectedStatus) {
          res.add(combined);
        }
      }
      return res;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _displayAssets;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Danh sách tài sản'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedRoomId,
                        isExpanded: true,
                        hint: const Text("Kho / Tất cả", style: TextStyle(fontSize: 13)),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Kho tổng chứa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          ..._rooms.map((r) => DropdownMenuItem<String?>(
                            value: r['id'],
                            child: Text(r['roomName'] ?? 'Phòng', style: const TextStyle(fontSize: 13)),
                          )).toList(),
                        ],
                        onChanged: (v) => setState(() => _selectedRoomId = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        items: ['Tất cả trạng thái', 'Hoạt động tốt', 'Không hoạt động', 'Hư hỏng nhẹ', 'Đang sửa chữa']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("Không có tài sản nào"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = item['assetName'] ?? 'Tài sản';
                      final value = (item['value'] ?? 0).toDouble();
                      final totalQty = (item['quantity'] ?? 1).toInt();
                      
                      final isGlobalView = _selectedRoomId == null;
                      final usedQty = isGlobalView ? (item['usedQuantity'] ?? 0) : totalQty;
                      final availableQty = totalQty - usedQty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(_getIconData(item['iconTag']), color: Colors.black87),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${_currencyFormat.format(value)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: isGlobalView 
                                ? Row(
                                    children: [
                                      Text('Kho: $availableQty', style: const TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      const Text('|'),
                                      const SizedBox(width: 8),
                                      Text('Đang cho thuê: $usedQty/$totalQty', style: const TextStyle(color: Colors.black54)),
                                    ],
                                  )
                                : Text('Số lượng: $totalQty Cái/Chiếc', style: const TextStyle(color: Colors.black54)),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditAssetModal(item);
                              } else if (value == 'delete') {
                                _deleteAsset(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Xoá'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A651),
        onPressed: () async {
          if (_selectedRoomId != null) {
            // Room Selected: Navigate to Smart Selection Page
            final room = _rooms.firstWhere((r) => r['id'] == _selectedRoomId);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageAssetsPage(
                  houseId: widget.houseId,
                  roomId: _selectedRoomId,
                  roomName: room['roomName'] ?? 'Phòng',
                ),
              ),
            );
            if (result == true) {
              _fetchData(); // Refresh list if something changed
            }
          } else {
            // No Room Selected: Show Global Warehouse Modal
            _showAddAssetModal();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------
// ADD ASSET FORM (No Room Selection per user's constraint)
// ---------------------------------------------------------

class _AddAssetForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final int? maxAllowed;
  final Function(Map<String, dynamic>) onSave;

  const _AddAssetForm({
    required this.onSave,
    this.initialData,
    this.maxAllowed,
  });

  @override
  State<_AddAssetForm> createState() => _AddAssetFormState();
}

class _AddAssetFormState extends State<_AddAssetForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _importPriceCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _supplierCtrl;
  late TextEditingController _unitCtrl;
  String _selectedStatus = 'Hoạt động tốt';
  String _selectedIcon = 'Tủ lạnh';

  final List<String> _icons = ['Tủ lạnh', 'Máy giặt', 'Điều hòa', 'Giường', 'Tủ quần áo', 'Bàn ghế'];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameCtrl = TextEditingController(text: data?['assetName'] ?? '');
    _valueCtrl = TextEditingController(text: data?['value']?.toString() ?? '');
    _importPriceCtrl = TextEditingController(text: data?['importPrice']?.toString() ?? '');
    _quantityCtrl = TextEditingController(text: data?['quantity']?.toString() ?? '');
    _supplierCtrl = TextEditingController(text: data?['supplier'] ?? '');
    _unitCtrl = TextEditingController(text: data?['unit'] ?? '');
    
    if (data?['status'] != null) {
      _selectedStatus = data!['status'];
    }
    if (data?['iconTag'] != null) {
      _selectedIcon = data!['iconTag'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _importPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _supplierCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

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
                Text(widget.initialData == null ? "Tạo kiện tài sản tổng" : "Chỉnh sửa tài sản", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                IconButton(icon: const Icon(Icons.close, color: Colors.black54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            if (widget.initialData == null) 
              const Text("Tài sản tạo tại đây sẽ được lưu vào kho tổng. Bạn phân bổ tài sản vào phòng khi thêm vào Hợp đồng.", style: TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic)),
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
                Expanded(child: _buildTextField("Giá trị tài sản", _valueCtrl, isNumber: true, hint: "VNĐ")),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Giá nhập vào", _importPriceCtrl, isNumber: true, hint: "VNĐ")),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField("Số lượng (Kho) (*)", _quantityCtrl, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Đơn vị tính", _unitCtrl, hint: "Cái/Chiếc")),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField("Nhà cung cấp", _supplierCtrl),
            const SizedBox(height: 16),
            const Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: ['Hoạt động tốt', 'Không hoạt động', 'Hư hỏng nhẹ', 'Đang sửa chữa'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
              ),
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
                  final qty = int.tryParse(_quantityCtrl.text) ?? 1;
                  if (widget.maxAllowed != null && qty > widget.maxAllowed!) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Số lượng vượt quá kho cho phép (Tối đa trong kho: ${widget.maxAllowed})"),
                      backgroundColor: Colors.redAccent,
                    ));
                    return;
                  }

                  final doc = {
                    'assetName': _nameCtrl.text,
                    'iconTag': _selectedIcon,
                    'value': double.tryParse(_valueCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                    'importPrice': double.tryParse(_importPriceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                    'quantity': qty,
                    'supplier': _supplierCtrl.text,
                    'unit': _unitCtrl.text.isNotEmpty ? _unitCtrl.text : 'Cái',
                    'status': _selectedStatus,
                  };
                  widget.onSave(doc);
                  Navigator.pop(context);
                },
                child: Text(widget.initialData == null ? "Tạo tài sản vào kho" : "Cập nhật tài sản", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, String? hint, List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
