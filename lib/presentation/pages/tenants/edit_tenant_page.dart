import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTenantPage extends StatefulWidget {
  final String houseId;
  final String contractId;
  final String? tenantSubId;
  final String roomName;
  final Map<String, dynamic> tenantData;

  const EditTenantPage({
    super.key,
    required this.houseId,
    required this.contractId,
    this.tenantSubId,
    required this.roomName,
    required this.tenantData,
  });

  @override
  State<EditTenantPage> createState() => _EditTenantPageState();
}

class _EditTenantPageState extends State<EditTenantPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Basic info
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _useApp = false;
  String _gender = 'Nam';

  // Additional info
  late TextEditingController _birthdayCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cccdNumberCtrl;
  late TextEditingController _cccdDateCtrl;
  late TextEditingController _cccdPlaceCtrl;
  bool _showAdditionalInfo = false;

  // Vehicle management
  List<Map<String, dynamic>> _vehicles = [];

  // Residence info
  late TextEditingController _residenceDateCtrl;
  late TextEditingController _residenceExpiryCtrl;
  late TextEditingController _relationshipCtrl;
  String _reportTemplate = 'CT01 (Mặc định LOZIDO)';

  // Toggle states
  bool _isContact = false;
  bool _hasCompleteDocs = false;
  bool _hasRegisteredResidence = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final d = widget.tenantData;

    _nameCtrl = TextEditingController(text: d['tenantName']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: d['phoneNumber']?.toString() ?? '');
    _useApp = d['useApp'] == true;
    _gender = d['gender']?.toString() ?? 'Nam';

    _birthdayCtrl = TextEditingController(text: d['birthday']?.toString() ?? '');
    _occupationCtrl = TextEditingController(text: d['occupation']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: d['address']?.toString() ?? '');
    _cccdNumberCtrl = TextEditingController(text: d['cccdNumber']?.toString() ?? '');
    _cccdDateCtrl = TextEditingController(text: d['cccdDate']?.toString() ?? '');
    _cccdPlaceCtrl = TextEditingController(text: d['cccdPlace']?.toString() ?? '');

    _vehicles = List<Map<String, dynamic>>.from(
      (d['vehicles'] as List<dynamic>?)?.map((v) => Map<String, dynamic>.from(v as Map)) ?? [],
    );

    _residenceDateCtrl = TextEditingController(text: d['residenceRegistrationDate']?.toString() ?? '');
    _residenceExpiryCtrl = TextEditingController(text: d['residenceExpiryDate']?.toString() ?? '');
    _relationshipCtrl = TextEditingController(text: d['relationship']?.toString() ?? '');
    _reportTemplate = d['reportTemplate']?.toString() ?? 'CT01 (Mặc định LOZIDO)';

    _isContact = d['isContact'] == true;
    _hasCompleteDocs = d['hasCompleteDocs'] == true;
    _hasRegisteredResidence = d['hasRegisteredResidence'] == true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthdayCtrl.dispose();
    _occupationCtrl.dispose();
    _addressCtrl.dispose();
    _cccdNumberCtrl.dispose();
    _cccdDateCtrl.dispose();
    _cccdPlaceCtrl.dispose();
    _residenceDateCtrl.dispose();
    _residenceExpiryCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A651),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updateData = <String, dynamic>{
        'useApp': _useApp,
        'gender': _gender,
        'birthday': _birthdayCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'cccdNumber': _cccdNumberCtrl.text.trim(),
        'cccdDate': _cccdDateCtrl.text.trim(),
        'cccdPlace': _cccdPlaceCtrl.text.trim(),
        'vehicles': _vehicles,
        'residenceRegistrationDate': _residenceDateCtrl.text.trim(),
        'residenceExpiryDate': _residenceExpiryCtrl.text.trim(),
        'relationship': _relationshipCtrl.text.trim(),
        'reportTemplate': _reportTemplate,
        'isContact': _isContact,
        'hasCompleteDocs': _hasCompleteDocs,
        'hasRegisteredResidence': _hasRegisteredResidence,
      };

      final contractRef = FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .doc(widget.contractId);

      if (widget.tenantSubId != null) {
        // Sub-tenant: store name/phone as 'name'/'phone'
        updateData['name'] = _nameCtrl.text.trim();
        updateData['phone'] = _phoneCtrl.text.trim();
        updateData['id'] = widget.tenantSubId;

        // Try to update in array first
        final contractDoc = await contractRef.get();
        bool updatedInArray = false;
        
        if (contractDoc.exists) {
          final arr = List<dynamic>.from(contractDoc.data()?['tenant'] ?? []);
          final idx = arr.indexWhere((e) => (e as Map)['id'] == widget.tenantSubId);
          if (idx != -1) {
            final oldData = Map<String, dynamic>.from(arr[idx] as Map);
            // Merge old data with new data
            oldData.addAll(updateData);
            arr[idx] = oldData;
            
            await contractRef.update({'tenant': arr});
            updatedInArray = true;
          }
        }

        if (!updatedInArray) {
          // Fallback: update in tenants sub-collection
          await contractRef
              .collection('tenants')
              .doc(widget.tenantSubId)
              .update(updateData);
        }
      } else {
        // Primary tenant: store as 'tenantName'/'phoneNumber'
        updateData['tenantName'] = _nameCtrl.text.trim();
        updateData['phoneNumber'] = _phoneCtrl.text.trim();

        await contractRef.update(updateData);

        // Also update room data for the primary tenant
        final contractDoc = await contractRef.get();
        if (contractDoc.exists) {
          final roomId = contractDoc.data()?['roomId'];
          if (roomId != null) {
            await FirebaseFirestore.instance
                .collection('houses')
                .doc(widget.houseId)
                .collection('rooms')
                .doc(roomId)
                .update({
              'tenantName': _nameCtrl.text.trim(),
              'tenantPhone': _phoneCtrl.text.trim(),
              'useApp': _useApp,
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thông tin thành công!')),
        );
        Navigator.pop(context, true); // Return true to signal data changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddVehicleDialog() {
    final typeCtrl = TextEditingController();
    final plateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, color: Color(0xFF00A651), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Thêm phương tiện', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(typeCtrl, 'Loại xe (VD: Xe máy)', Icons.category_outlined),
              const SizedBox(height: 12),
              _buildDialogTextField(plateCtrl, 'Biển số xe', Icons.confirmation_number_outlined),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (typeCtrl.text.trim().isEmpty && plateCtrl.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  _vehicles.add({
                    'type': typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : 'Xe',
                    'plate': plateCtrl.text.trim(),
                  });
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
        prefixIcon: Icon(icon, size: 20, color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00A651)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  void _showRelationshipPicker() {
    final options = ['Chủ hộ', 'Vợ/Chồng', 'Con', 'Bố/Mẹ', 'Anh/Chị/Em', 'Cháu', 'Khác'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A651).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.tag, color: Color(0xFF00A651), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Mẫu quan hệ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...options.map((opt) => ListTile(
                    title: Text(opt, style: const TextStyle(fontSize: 15)),
                    trailing: _relationshipCtrl.text == opt
                        ? const Icon(Icons.check_circle, color: Color(0xFF00A651), size: 20)
                        : null,
                    onTap: () {
                      setState(() => _relationshipCtrl.text = opt);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sửa thông tin khách',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              widget.roomName,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              _buildEditAvatar(initial),
              const SizedBox(height: 20),

              // Basic info section
              _buildBasicInfoSection(),
              const SizedBox(height: 8),

              // Additional info expandable
              _buildAdditionalInfoToggle(),
              const SizedBox(height: 8),

              // Vehicle section
              _buildVehicleSection(),
              const SizedBox(height: 8),

              // Residence section
              _buildResidenceSection(),
              const SizedBox(height: 8),

              // Toggle switches section
              _buildToggleSwitchesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEditAvatar(String initial) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2196F3),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF00A651),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & Phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Tên khách thuê',
                  controller: _nameCtrl,
                  isRequired: true,
                  hint: 'Nhập tên khách',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Số điện thoại',
                  controller: _phoneCtrl,
                  hint: 'Nhập SĐT',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Use App checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              border: Border.all(color: const Color(0xFF00A651).withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _useApp,
                  onChanged: (v) => setState(() => _useApp = v ?? false),
                  activeColor: const Color(0xFF00A651),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cho phép sử dụng APP - Khách thuê',
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      Text(
                        'Gửi hóa đơn tự động cho khách, hợp đồng online vv...',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gender selector
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Giới tính',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13),
            children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _gender,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              IconButton(
                icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                onSelected: (v) => setState(() => _gender = v),
                itemBuilder: (context) => ['Nam', 'Nữ', 'Khác'].map((g) {
                  return PopupMenuItem(value: g, child: Text(g));
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoToggle() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _showAdditionalInfo = !_showAdditionalInfo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAdditionalInfo ? Icons.expand_less : Icons.open_in_full,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Thông tin khác của khách',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_showAdditionalInfo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildFormField(
                    label: 'Ngày sinh',
                    controller: _birthdayCtrl,
                    hint: 'dd/MM/yyyy',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _pickDate(_birthdayCtrl),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Nghề nghiệp', controller: _occupationCtrl, hint: 'Nhập nghề nghiệp'),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Địa chỉ', controller: _addressCtrl, hint: 'Nhập địa chỉ'),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Số CCCD/Passport', controller: _cccdNumberCtrl, hint: 'Nhập số CCCD'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Ngày cấp CCCD',
                          controller: _cccdDateCtrl,
                          hint: 'Chọn ngày',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () => _pickDate(_cccdDateCtrl),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(label: 'Nơi cấp CCCD', controller: _cccdPlaceCtrl, hint: 'Nhập nơi cấp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildSectionHeader(Icons.tag, 'Quản lý phương tiện', 'Quản lý xe, phương tiện của khách thuê'),
          const SizedBox(height: 16),

          if (_vehicles.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.directions_bike, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có phương tiện nào được thêm...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_vehicles.length, (i) {
              final v = _vehicles[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_outlined, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${v['type'] ?? 'Xe'} - ${v['plate'] ?? ''}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _vehicles.removeAt(i)),
                      child: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _showAddVehicleDialog,
              icon: const Icon(Icons.add, size: 18, color: Colors.black87),
              label: const Text('Thêm phương tiện', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.tag, 'Thông tin tờ khai tạm trú', 'Nhập thông tin tạm trú của khách'),
          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: _buildDatePickerTile(
                  label: 'Ngày đăng ký tạm trú',
                  controller: _residenceDateCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerTile(
                  label: 'Ngày hết hạn tạm trú',
                  controller: _residenceExpiryCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Relationship
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quan hệ với chủ hộ',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Mối quan hệ với chủ hộ khi làm tạm trú',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _relationshipCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Quan hệ với chủ hộ',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00A651))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showRelationshipPicker,
                    icon: const Icon(Icons.tag, size: 16, color: Color(0xFF00A651)),
                    label: const Text('Mẫu quan hệ', style: TextStyle(color: Color(0xFF00A651), fontSize: 13, fontWeight: FontWeight.w500)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00A651)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Report template
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mẫu tạm trú', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text(_reportTemplate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _reportTemplate = 'CT01 (Mặc định LOZIDO)'),
                  child: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              text: '* Bạn có thể chỉnh sửa mẫu tạm trú ',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              children: [
                TextSpan(
                  text: 'trên phiên bản máy tính',
                  style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitchesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildToggleTile(
            title: 'Người liên hệ',
            subtitle: 'Người chịu trách nhiệm liên hệ, Nhận thông báo tiền thuê trọ...',
            value: _isContact,
            onChanged: (v) => setState(() => _isContact = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildToggleTile(
            title: 'Giấy tờ tùy thân / Đã xác thực',
            subtitle: 'Đã đầy đủ giấy tờ tùy thân hay chưa ?',
            value: _hasCompleteDocs,
            onChanged: (v) => setState(() => _hasCompleteDocs = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildToggleTile(
            title: 'Tình trạng đăng ký tạm trú',
            subtitle: 'Xác định khách thuê đã được đăng ký tạm trú hay chưa ?',
            value: _hasRegisteredResidence,
            onChanged: (v) => setState(() => _hasRegisteredResidence = v),
          ),
        ],
      ),
    );
  }

  // ──────── Reusable widgets ────────

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    String? hint,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13),
            children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập' : null : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00A651))),
            suffixIcon: suffixIcon,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required TextEditingController controller,
  }) {
    return GestureDetector(
      onTap: () => _pickDate(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(
                    controller.text.isNotEmpty ? controller.text : 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: controller.text.isNotEmpty ? Colors.black87 : const Color(0xFF00A651),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00A651).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00A651), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00A651),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white,
                ),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTenant,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.edit, size: 18),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Lưu khách thuê',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
