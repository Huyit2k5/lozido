import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddServicePage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const AddServicePage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isMetered = false;
  String? _selectedUnit;
  bool _isLoading = false;

  // Validation errors
  String? _nameError;
  String? _unitError;
  String? _priceError;

  // Room selection
  Set<String> _selectedRoomIds = {};
  bool _selectAllRooms = false;

  // Chip suggestions
  final List<String> _suggestions = ['Tiền giữ xe', 'Tiền wifi', 'Tiền nước (người)'];

  // Unit options
  final List<String> _unitOptions = [
    'KWh', 'Khối', 'Tháng', 'Người', 'Chiếc',
    'Lần', 'Cái', 'Bình', 'm2', 'Giờ',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showUnitSelector() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Chọn đơn vị',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              const Divider(height: 1),
              ..._unitOptions.map((unit) => ListTile(
                title: Text(
                  unit,
                  style: TextStyle(
                    fontWeight: _selectedUnit == unit ? FontWeight.bold : FontWeight.normal,
                    color: _selectedUnit == unit ? const Color(0xFF00A651) : Colors.black87,
                  ),
                ),
                trailing: _selectedUnit == unit
                    ? const Icon(Icons.check, color: Color(0xFF00A651))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedUnit = unit;
                    _unitError = null;
                  });
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _unitError = null;
      _priceError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Vui lòng nhập tên dịch vụ';
        valid = false;
      }
      if (_selectedUnit == null) {
        _unitError = 'Vui lòng chọn đơn vị';
        valid = false;
      }
      if (_priceController.text.trim().isEmpty) {
        _priceError = 'Vui lòng nhập giá dịch vụ';
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _submitService() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('services')
          .add({
        'serviceName': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'unit': _selectedUnit,
        'isMetered': _isMetered,
        'appliedRooms': _selectedRoomIds.toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF00A651), size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thêm thành công',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dịch vụ "${_nameController.text.trim()}" đã được thêm.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // close dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A651),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (mounted) {
          Navigator.pop(context); // go back to list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll(bool? value, List<QueryDocumentSnapshot> roomDocs) {
    setState(() {
      _selectAllRooms = value ?? false;
      if (_selectAllRooms) {
        _selectedRoomIds = roomDocs.map((d) => d.id).toSet();
      } else {
        _selectedRoomIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm mới dịch vụ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Section 1: Tên dịch vụ ----
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tên dịch vụ', isRequired: true),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Tên dịch vụ',
                            hintStyle: const TextStyle(color: Colors.black38),
                            errorText: _nameError,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF00A651)),
                            ),
                          ),
                          onChanged: (_) {
                            if (_nameError != null) setState(() => _nameError = null);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ví dụ đề xuất:',
                          style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestions.map((s) => GestureDetector(
                            onTap: () {
                              _nameController.text = s;
                              setState(() => _nameError = null);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF00A651)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  color: Color(0xFF00A651),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---- Section 2: Tính theo đồng hồ ----
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon đồng hồ
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.speed, color: Colors.black54, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tính theo kiểu đồng hồ điện, nước ?',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mức sử dụng của khách thuê có sự chênh lệch trước & sau',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isMetered,
                              activeThumbColor: const Color(0xFF00A651),
                              onChanged: (val) => setState(() => _isMetered = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '* Ví dụ: Dịch vụ điện, nước có sự chênh lệch số cũ và số mới',
                          style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---- Section 3: Đơn vị và giá ----
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đơn vị và giá',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nhập thông tin đơn vị tính và giá dịch vụ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Đơn vị field
                        _buildLabel('Đơn vị', isRequired: true),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showUnitSelector,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _unitError != null ? Colors.red : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedUnit ?? 'Chọn đơn vị',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedUnit != null ? Colors.black87 : Colors.black38,
                                    fontWeight: _selectedUnit != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _selectedUnit != null
                                      ? () => setState(() => _selectedUnit = null)
                                      : _showUnitSelector,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _selectedUnit != null ? Icons.close : Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_unitError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 12),
                            child: Text(
                              _unitError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Giá dịch vụ field
                        _buildLabel('Giá dịch vụ', isRequired: true),
                        const SizedBox(height: 4),
                        const Text(
                          'Ví dụ Tiền rác: 30.000 đ / 1 người, bạn nhập là 30000',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: 'Nhập giá dịch vụ',
                            hintStyle: const TextStyle(color: Colors.black38),
                            errorText: _priceError,
                            suffixIcon: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Đồng/${_selectedUnit ?? 'Tháng'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF00A651)),
                            ),
                          ),
                          onChanged: (_) {
                            if (_priceError != null) setState(() => _priceError = null);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---- Section 4: Chọn phòng sử dụng ----
                  _buildRoomSelector(),

                  // Bottom padding for button
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Thêm mới dịch vụ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        final roomDocs = snapshot.data?.docs ?? [];

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn phòng sử dụng (${_selectedRoomIds.length} đã chọn)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Nhấp chọn các phòng muốn áp dụng dịch vụ này',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Checkbox(
                        value: _selectAllRooms,
                        activeColor: const Color(0xFF00A651),
                        onChanged: (val) => _toggleSelectAll(val, roomDocs),
                      ),
                      const Text(
                        'Chọn tất cả',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFF00A651)),
                  ),
                )
              else if (roomDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Chưa có phòng nào trong nhà trọ này',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                // Room grid: 2 columns
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: roomDocs.length,
                  itemBuilder: (context, index) {
                    final doc = roomDocs[index];
                    final roomData = doc.data() as Map<String, dynamic>;
                    final roomName = roomData['roomName'] ?? 'Phòng ${index + 1}';
                    final isSelected = _selectedRoomIds.contains(doc.id);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedRoomIds.remove(doc.id);
                            _selectAllRooms = false;
                          } else {
                            _selectedRoomIds.add(doc.id);
                            if (_selectedRoomIds.length == roomDocs.length) {
                              _selectAllRooms = true;
                            }
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF00A651),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedRoomIds.add(doc.id);
                                      if (_selectedRoomIds.length == roomDocs.length) {
                                        _selectAllRooms = true;
                                      }
                                    } else {
                                      _selectedRoomIds.remove(doc.id);
                                      _selectAllRooms = false;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    roomName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isSelected ? 'Đang áp dụng' : 'Không áp dụng',
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF00A651) : Colors.deepOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        children: isRequired
            ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
            : [],
      ),
    );
  }
}
