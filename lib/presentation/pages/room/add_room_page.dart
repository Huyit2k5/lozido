import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'service_selection_page.dart';

class AddRoomPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;
  final String? roomId;
  final Map<String, dynamic>? initialRoomData;

  const AddRoomPage({
    super.key,
    required this.houseId,
    required this.houseData,
    this.roomId,
    this.initialRoomData,
  });

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _billingCycleController = TextEditingController(text: '1');

  int? _selectedFloor;
  String _selectedPriority = 'Tất cả';

  final List<String> _priorityOptions = [
    'Tất cả',
    'Ưu tiên nữ',
    'Ưu tiên nam',
    'Ưu tiên gia đình'
  ];

  List<Map<String, dynamic>> _selectedServices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomData != null) {
      final data = widget.initialRoomData!;
      _roomNameController.text = data['roomName']?.toString() ?? '';
      
      final area = data['area'];
      if (area != null) _areaController.text = area == area.roundToDouble() ? area.toInt().toString() : area.toString();
      
      final price = data['price'];
      if (price != null) _priceController.text = price == price.roundToDouble() ? price.toInt().toString() : price.toString();

      _billingCycleController.text = data['billingCycleDay']?.toString() ?? '1';
      _selectedFloor = data['floor'];
      _selectedPriority = data['priority'] ?? 'Tất cả';

      if (data['services'] != null) {
        _selectedServices = List<Map<String, dynamic>>.from(data['services']);
      }
    }
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _billingCycleController.dispose();
    super.dispose();
  }

  int get _floorCount {
    return int.tryParse(widget.houseData['floorCount']?.toString() ?? '1') ?? 1;
  }

  void _showFloorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Chọn Nhóm (Tầng/dãy/khu)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _floorCount,
                  itemBuilder: (context, index) {
                    final floorNumber = index + 1;
                    return ListTile(
                      title: Text('Tầng $floorNumber'),
                      trailing: _selectedFloor == floorNumber
                          ? const Icon(Icons.check, color: Color(0xFF00A651))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedFloor = floorNumber;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Ưu tiên người thuê',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ..._priorityOptions.map((priority) => ListTile(
                    title: Text(priority),
                    trailing: _selectedPriority == priority
                        ? const Icon(Icons.check, color: Color(0xFF00A651))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPriority = priority;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedFloor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Nhóm (Tầng/dãy)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final roomData = {
        'roomName': _roomNameController.text.trim(),
        'floor': _selectedFloor,
        'area': double.tryParse(_areaController.text.trim()) ?? 0.0,
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'billingCycleDay': int.tryParse(_billingCycleController.text.trim()) ?? 1,
        'priority': _selectedPriority,
        'status': 'Đang trống',
        'services': _selectedServices.map((e) => {
          'name': e['name'],
          'price': e['price'],
          'unit': e['unit'],
          'currentIndex': e['currentIndex'],
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      bool isEdit = widget.roomId != null;
      final docRef = FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .doc(isEdit ? widget.roomId : null);

      if (isEdit) {
        final updateData = Map<String, dynamic>.from(roomData);
        updateData.remove('createdAt');
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(updateData);
      } else {
        await docRef.set(roomData);

        // Increment roomCount on house document only when adding
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .update({
          'roomCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Cập nhật phòng thành công!' : 'Thêm phòng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm phòng: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          widget.roomId != null ? 'Chỉnh sửa phòng' : 'Thêm phòng',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)))
          : Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildSectionHeader(
                    icon: Icons.tag,
                    title: 'Thông tin cơ bản',
                    subtitle: 'Tên, giá thuê, diện tích, ngày lập hóa đơn',
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tên phòng trọ', isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _roomNameController,
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: Phòng số 1',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Vui lòng nhập tên phòng' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Nhóm (Tầng/dãy/khu)', isRequired: true),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showFloorPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedFloor != null ? 'Tầng $_selectedFloor' : 'Chọn giá trị',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedFloor != null ? Colors.black87 : Colors.black87,
                                    fontWeight: _selectedFloor != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Diện tích', isRequired: true),
                                  const Text('Nhập diện tích phòng', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _areaController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Diện tích',
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('m2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Bắt buộc' : null,
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Giá thuê', isRequired: true),
                                  const Text('Giá phòng tính đơn vị theo tháng', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  hintText: 'Giá thuê',
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('đ/tháng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Bắt buộc' : null,
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Ngày lập hóa đơn', isRequired: true),
                                  const Text('Hệ thống sẽ nhắc nhở khi phòng tới ngày lập hóa đơn', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _billingCycleController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Bắt buộc';
                                  int? val = int.tryParse(value);
                                  if (val == null || val < 1 || val > 31) return 'Ngày từ 1-31';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

                        InkWell(
                          onTap: _showPriorityPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Ưu tiên người thuê', isRequired: true),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedPriority,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionHeader(
                    icon: Icons.tag,
                    title: 'Dịch vụ sử dụng',
                    subtitle: 'Tiền điện, nước, rác, wifi...',
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      children: [
                        if (_selectedServices.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26),
                                SizedBox(height: 12),
                                Text(
                                  'Hiện chưa có dịch vụ nào được áp dụng...',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          )
                        ] else ...[
                          ..._selectedServices.map((svc) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          svc['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatCurrency(svc['price'])} đ/1 ${svc['unit']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Text('Số hiện tại: ${svc['currentIndex']}', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceSelectionPage(
                                    initialSelectedServices: _selectedServices,
                                  ),
                                ),
                              );

                              if (result != null && result is List<Map<String, dynamic>>) {
                                setState(() {
                                  _selectedServices = result;
                                });
                              }
                            },
                            icon: const Icon(Icons.edit, color: Colors.black87, size: 18),
                            label: const Text('Chỉnh sửa dịch vụ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // padding for bottom buttons
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đóng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: Icon(widget.roomId != null ? Icons.save : Icons.add, color: Colors.white),
                label: Text(
                  widget.roomId != null ? 'Lưu thông tin' : 'Thêm phòng',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15),
        children: isRequired
            ? [
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ]
            : [],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle}) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    String str = amount.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = str[i] + result;
      count++;
    }
    return result;
  }
}
