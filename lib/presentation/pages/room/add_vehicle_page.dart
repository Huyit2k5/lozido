import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehiclePage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const AddVehiclePage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _vehicleNameCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();

  String? _selectedRoomId;
  String? _selectedRoomName;
  String? _selectedTenantName;

  List<Map<String, dynamic>> _rooms = [];
  List<String> _tenants = [];

  bool _isLoadingRooms = true;
  bool _isLoadingTenants = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  void dispose() {
    _vehicleNameCtrl.dispose();
    _licensePlateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .get();

      if (mounted) {
        setState(() {
          _rooms = qs.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  Future<void> _fetchTenants(String roomId) async {
    setState(() {
      _isLoadingTenants = true;
      _tenants = [];
      _selectedTenantName = null;
    });

    try {
      final qs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['Active', 'Còn hạn', 'Đang hiệu lực'])
          .get();

      final tenantNames = <String>{};
      for (var doc in qs.docs) {
        final data = doc.data();
        final name = data['tenantName']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          tenantNames.add(name);
        }
      }

      if (mounted) {
        setState(() {
          _tenants = tenantNames.toList();
          _isLoadingTenants = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
      if (mounted) setState(() => _isLoadingTenants = false);
    }
  }

  Future<void> _submitVehicle() async {
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng')),
      );
      return;
    }
    if (_selectedTenantName == null || _selectedTenantName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách thuê')),
      );
      return;
    }
    if (_vehicleNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên xe')),
      );
      return;
    }
    if (_licensePlateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập biển số xe')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('vehicles')
          .add({
        'vehicleName': _vehicleNameCtrl.text.trim(),
        'licensePlate': _licensePlateCtrl.text.trim(),
        'roomId': _selectedRoomId,
        'roomName': _selectedRoomName ?? '',
        'tenantName': _selectedTenantName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm phương tiện thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          'Phương tiện của khách thuê',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dropdown section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Room dropdown
                  Expanded(
                    child: _buildDropdownContainer(
                      label: 'Chọn phòng',
                      child: _isLoadingRooms
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                isDense: true,
                                value: _selectedRoomId,
                                hint: const Text(
                                  'Chọn giá trị',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                items: _rooms.map((room) {
                                  return DropdownMenuItem<String?>(
                                    value: room['id'],
                                    child: Text(
                                      room['roomName'] ?? room['name'] ?? 'Phòng',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedRoomId = val;
                                    if (val != null) {
                                      final room = _rooms.firstWhere(
                                        (r) => r['id'] == val,
                                        orElse: () => <String, dynamic>{},
                                      );
                                      _selectedRoomName = room['roomName'] ?? room['name'] ?? '';
                                    }
                                  });
                                  if (val != null) {
                                    _fetchTenants(val);
                                  }
                                },
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tenant dropdown
                  Expanded(
                    child: _buildDropdownContainer(
                      label: 'Khách thuê',
                      child: _isLoadingTenants
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                isDense: true,
                                value: _selectedTenantName,
                                hint: const Text(
                                  'Chọn giá trị',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                items: _tenants.map((name) {
                                  return DropdownMenuItem<String?>(
                                    value: name,
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedTenantName = val;
                                  });
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            // Vehicle name
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildTextField(
                label: 'Tên xe',
                controller: _vehicleNameCtrl,
                hint: 'Ví dụ: Wave alpha',
                isRequired: true,
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            // License plate
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _buildTextField(
                label: 'Biển số xe',
                controller: _licensePlateCtrl,
                hint: 'Ví dụ: 93B - 12345',
                isRequired: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitVehicle,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text(
                    'Thêm xe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
