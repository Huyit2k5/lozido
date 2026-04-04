import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'contract_provider.dart';
import 'create_contract_page.dart';

class ManageAssetsPage extends StatefulWidget {
  const ManageAssetsPage({super.key});

  @override
  State<ManageAssetsPage> createState() => _ManageAssetsPageState();
}

class _ManageAssetsPageState extends State<ManageAssetsPage> {
  // Temporary list to hold newly created ones and currently selected ones
  List<ContractAsset> _availableAssets = [];
  Set<int> _selectedIndices = {};

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    // Load from provider initially
    final currentAssets = Provider.of<ContractProvider>(context, listen: false).assets;
    _availableAssets = List.from(currentAssets);
    
    // Initially all existing ones are selected
    for (int i = 0; i < _availableAssets.length; i++) {
      _selectedIndices.add(i);
    }
  }

  void _showAddAssetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAssetForm(
        onAdd: (asset) {
          setState(() {
            _availableAssets.add(asset);
            _selectedIndices.add(_availableAssets.length - 1);
          });
        },
      ),
    );
  }

  IconData _getIconData(String name) {
    if (name.contains('Tủ lạnh')) return Icons.kitchen;
    if (name.contains('Máy giặt')) return Icons.local_laundry_service;
    if (name.contains('Điều hòa')) return Icons.ac_unit;
    if (name.contains('Giường')) return Icons.bed;
    if (name.contains('Bàn')) return Icons.desk;
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
          "Thêm/bớt tài sản",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAddAssetModal,
            icon: const Icon(Icons.settings_outlined, color: Colors.blueAccent, size: 20),
            label: const Text("Cài đặt", style: TextStyle(color: Colors.blueAccent)),
          )
        ],
      ),
      body: _availableAssets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chair_alt_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("Chưa có tài sản nào để quản lý...", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _showAddAssetModal,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Thêm tài sản mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableAssets.length,
              itemBuilder: (context, index) {
                final asset = _availableAssets[index];
                final isSelected = _selectedIndices.contains(index);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIconData(asset.iconTag), color: Colors.black87, size: 24),
                    ),
                    title: Text(
                      asset.assetName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(asset.value),
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSelected ? "Đang sử dụng" : "Không sử dụng",
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00A651) : Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(index);
                          } else {
                            _selectedIndices.add(index);
                          }
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade400, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          color: isSelected ? const Color(0xFF00A651) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
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
                  child: const Text("Đóng", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
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
                    final selectedAssets = _selectedIndices.map((i) => _availableAssets[i]).toList();
                    Provider.of<ContractProvider>(context, listen: false).updateAssets(selectedAssets);
                    Navigator.pop(context);
                  },
                  child: const Text("Áp dụng tài sản", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAssetForm extends StatefulWidget {
  final Function(ContractAsset) onAdd;

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
                const Text("Thêm tài sản mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                Expanded(child: _buildTextField("Giá trị tài sản", _valueCtrl, isNumber: true, hint: "VNĐ", formatters: [CurrencyInputFormatter()])),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Giá nhập vào", _importPriceCtrl, isNumber: true, hint: "VNĐ", formatters: [CurrencyInputFormatter()])),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField("Số lượng (*)", _quantityCtrl, isNumber: true)),
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
                  if (_nameCtrl.text.isEmpty || _quantityCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên và số lượng")));
                    return;
                  }
                  final asset = ContractAsset(
                    assetName: _nameCtrl.text,
                    iconTag: _selectedIcon,
                    value: double.tryParse(_valueCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                    importPrice: double.tryParse(_importPriceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
                    quantity: int.tryParse(_quantityCtrl.text) ?? 1,
                    supplier: _supplierCtrl.text,
                    unit: _unitCtrl.text.isNotEmpty ? _unitCtrl.text : 'Cái',
                    status: _selectedStatus,
                  );
                  widget.onAdd(asset);
                  Navigator.pop(context);
                },
                child: const Text("Xác nhận", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
