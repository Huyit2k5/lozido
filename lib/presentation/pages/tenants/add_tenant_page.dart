import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lozido_app/presentation/widgets/app_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTenantPage extends StatefulWidget {
  final String houseId;
  final String contractId;
  final String roomName;

  const AddTenantPage({
    super.key,
    required this.houseId,
    required this.contractId,
    required this.roomName,
  });

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
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
  final List<Map<String, dynamic>> _vehicles = [];

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
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _birthdayCtrl = TextEditingController();
    _occupationCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cccdNumberCtrl = TextEditingController();
    _cccdDateCtrl = TextEditingController();
    _cccdPlaceCtrl = TextEditingController();
    _residenceDateCtrl = TextEditingController();
    _residenceExpiryCtrl = TextEditingController();
    _relationshipCtrl = TextEditingController();
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
      final newTenantId = const Uuid().v4();
      final newTenantData = <String, dynamic>{
        'id': newTenantId,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
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

      await contractRef.update({
        'tenant': FieldValue.arrayUnion([newTenantData]),
      });

      if (mounted) {
        AppDialog.show(
          context, 
          title: "Thành công", 
          message: "Lưu thông tin khách thuê thành công!", 
          type: AppDialogType.success,
          onConfirm: () => Navigator.pop(context, true),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(context, title: "Lỗi", message: "Lỗi hệ thống: $e", type: AppDialogType.error);
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
              'Thêm thông tin khách',
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

          // // Use App checkbox
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
                  _buildScanBanner(),
                  const SizedBox(height: 16),
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

  Widget _buildScanBanner() {
    return InkWell(
      onTap: _showCCCDScanOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.document_scanner, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tải ảnh CCCD?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text("Quét ngay để tự động điền thông tin", style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Future<void> _showCCCDScanOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Quét thẻ Căn Cước Công Dân", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Chụp ảnh 2 mặt CCCD"),
              onTap: () {
                Navigator.pop(context);
                _processCCCDImagesFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("Chọn ảnh 2 mặt CCCD từ thư viện"),
              onTap: () {
                Navigator.pop(context);
                _processCCCDImagesFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCCCDImagesFromCamera() async {
    final picker = ImagePicker();
    
    // Front
    final frontFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (frontFile == null) return;
    
    // Dialog for Back
    if (mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Tiếp tục"),
          content: const Text("Vui lòng chụp mặt sau của CCCD để quét đầy đủ thông tin (Ngày cấp, Nơi cấp)."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Bỏ qua", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Chụp ảnh"),
            ),
          ],
        ),
      );
      
      if (shouldContinue == true) {
        final backFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
        if (backFile != null) {
          _processCCCDImages([frontFile, backFile]);
          return;
        }
      }
    }
    
    _processCCCDImages([frontFile]);
  }

  Future<void> _processCCCDImagesFromGallery() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      _processCCCDImages(images.take(2).toList());
    }
  }

  Future<void> _processCCCDImages(List<XFile> files) async {
    if (files.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final configDoc = await FirebaseFirestore.instance.collection('config').doc('google').get();
      final apiKey = configDoc.data()?['cloud_vision_api'] ?? '';
      
      if (apiKey.isEmpty) {
        throw Exception("Không tìm thấy Cloud Vision API Key. Vui lòng kiểm tra Firestore.");
      }

      List<Map<String, dynamic>> requests = [];
      for (var file in files) {
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        requests.add({
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        });
      }

      final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "requests": requests
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Lỗi gọi Cloud Vision API: ${response.body}");
      }

      final jsonResponse = jsonDecode(response.body);
      String combinedText = "";

      for (var res in jsonResponse['responses'] ?? []) {
         final annotations = res['textAnnotations'];
         if (annotations != null && annotations.isNotEmpty) {
            combinedText += annotations[0]['description'] + "\n";
         }
      }
      
      if (combinedText.trim().isEmpty) {
        throw Exception("Không tìm thấy văn bản trong ảnh");
      }

      String text = combinedText;

      String? cccd;
      String? name;
      String? dob;
      String? gender;
      String? address;
      String? issueDate;
      String? issuePlace;

      final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lowerLine = line.toLowerCase();
        
        // Front parsing
        if (cccd == null) {
          final cccdMatch = RegExp(r'\b\d{12}\b').firstMatch(line);
          if (cccdMatch != null) {
            cccd = cccdMatch.group(0);
          } else if (lowerLine.contains('số') || lowerLine.contains('no.')) {
            if (i + 1 < lines.length) {
              final nextLineMatch = RegExp(r'\b\d{12}\b').firstMatch(lines[i+1]);
              if (nextLineMatch != null) cccd = nextLineMatch.group(0);
            }
          }
        }

        if (name == null && (lowerLine.contains('họ và tên') || lowerLine.contains('full name'))) {
          String contentAfterLabel = line.replaceAll(RegExp(r'(họ và tên|full name)\s*[/:]*\s*', caseSensitive: false), '').trim();
          if (contentAfterLabel.length > 3) {
            name = contentAfterLabel.toUpperCase();
          } else if (i + 1 < lines.length) {
            name = lines[i+1].toUpperCase();
          }
        }

        if (dob == null && (lowerLine.contains('ngày sinh') || lowerLine.contains('date of birth'))) {
           final dobMatch = RegExp(r'\b\d{2}/\d{2}/\d{4}\b').firstMatch(line);
           if (dobMatch != null) {
             dob = dobMatch.group(0);
           } else if (i + 1 < lines.length) {
             final nextLineMatch = RegExp(r'\b\d{2}/\d{2}/\d{4}\b').firstMatch(lines[i+1]);
             if (nextLineMatch != null) dob = nextLineMatch.group(0);
           }
        }

        if (gender == null && (lowerLine.contains('giới tính') || lowerLine.contains('sex'))) {
           if (lowerLine.contains('nam')) {
             gender = 'Nam';
           } else if (lowerLine.contains('nữ')) {
             gender = 'Nữ';
           } else if (i + 1 < lines.length) {
             final nextLower = lines[i+1].toLowerCase();
             if (nextLower.contains('nam')) gender = 'Nam';
             else if (nextLower.contains('nữ')) gender = 'Nữ';
           }
        }

        if (address == null && (lowerLine.contains('thường trú') || lowerLine.contains('residence'))) {
           String currentLineContent = line.replaceAll(RegExp(r'(nơi thường trú|place of residence|residence)\s*[/:]*\s*', caseSensitive: false), '').trim();
           address = currentLineContent;

           int nextIdx = i + 1;
           while (nextIdx < lines.length) {
             String nextLine = lines[nextIdx].toLowerCase();
             if (nextLine.contains('có giá trị') || nextLine.contains('expiry') || 
                 nextLine.contains('đặc điểm') || nextLine.contains('identifying') ||
                 nextLine.contains('quê quán') || nextLine.contains('place of origin') ||
                 nextLine.contains('ngày, tháng, năm') || nextLine.contains('date, month, year')) {
               break;
             }
             
             if (address!.isEmpty) {
               address = lines[nextIdx];
             } else {
               address += ", " + lines[nextIdx];
             }
             nextIdx++;
           }
           i = nextIdx - 1;
        }

        // Back parsing
        if (issueDate == null && (lowerLine.contains('ngày, tháng, năm') || lowerLine.contains('date, month, year') || (lowerLine.contains('ngày') && lowerLine.contains('tháng') && lowerLine.contains('năm')))) {
           final issueDateMatch = RegExp(r'\b\d{2}/\d{2}/\d{4}\b').firstMatch(line);
           if (issueDateMatch != null && issueDateMatch.group(0) != dob) {
               issueDate = issueDateMatch.group(0);
           } else {
               int nextIdx = i + 1;
               while (nextIdx < lines.length && nextIdx <= i + 3) {
                   final nextMatch = RegExp(r'\b\d{2}/\d{2}/\d{4}\b').firstMatch(lines[nextIdx]);
                   if (nextMatch != null && nextMatch.group(0) != dob) {
                       issueDate = nextMatch.group(0);
                       break;
                   }
                   nextIdx++;
               }
           }
        }

        if (issuePlace == null) {
           if (lowerLine.contains('nơi cấp') || lowerLine.contains('place of issue')) {
               String currentLineContent = line.replaceAll(RegExp(r'(nơi cấp|place of issue)\s*[/:]*\s*', caseSensitive: false), '').trim();
               if (currentLineContent.isNotEmpty) {
                   issuePlace = currentLineContent;
               } else if (i + 1 < lines.length) {
                   issuePlace = lines[i+1];
               }
           } else if (lowerLine.contains('cục trưởng cục cảnh sát')) {
               issuePlace = line;
               if (i + 1 < lines.length && (lines[i+1].toLowerCase().contains('quản lý hành chính') || lines[i+1].toLowerCase().contains('cư trú'))) {
                   issuePlace = issuePlace! + ' ' + lines[i+1];
               }
           } else if (lowerLine.contains('quản lý hành chính về trật tự xã hội')) {
               issuePlace = "Cục Cảnh sát quản lý hành chính về trật tự xã hội";
           } else if (lowerLine.contains('giám đốc công an')) {
               issuePlace = line;
           }
        }
      }

      // Fallbacks
      if (cccd == null) {
        final cccdMatch = RegExp(r'\b\d{12}\b').firstMatch(text);
        if (cccdMatch != null) cccd = cccdMatch.group(0);
      }
      if (dob == null) {
        final dobMatches = RegExp(r'\b\d{2}/\d{2}/\d{4}\b').allMatches(text).map((m) => m.group(0)).toList();
        if (dobMatches.isNotEmpty) {
           dob = dobMatches.first;
        }
      }
      if (issueDate == null) {
        final dateMatches = RegExp(r'\b\d{2}/\d{2}/\d{4}\b').allMatches(text).map((m) => m.group(0)).toList();
        for (var d in dateMatches) {
            if (d != dob) {
                issueDate = d;
                break;
            }
        }
      }
      if (gender == null) {
        final genderMatch = RegExp(r'\b(Nam|Nữ)\b', caseSensitive: false).firstMatch(text);
        if (genderMatch != null) {
          String g = genderMatch.group(0) ?? '';
          gender = g.toLowerCase() == 'nam' ? 'Nam' : 'Nữ';
        }
      }

      if (mounted) {
        setState(() {
          if (cccd != null) _cccdNumberCtrl.text = cccd;
          if (dob != null) _birthdayCtrl.text = dob;
          if (gender != null) _gender = gender;
          if (name != null && name.isNotEmpty) _nameCtrl.text = name;
          if (address != null && address.isNotEmpty) _addressCtrl.text = address;
          if (issueDate != null) _cccdDateCtrl.text = issueDate;
          if (issuePlace != null) _cccdPlaceCtrl.text = issuePlace;
          _showAdditionalInfo = true; // Bật hiển thị form nếu có data
        });
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trích xuất OCR thành công!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xử lý OCR: $e")));
      }
    }
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
