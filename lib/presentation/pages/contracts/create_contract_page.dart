import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lozido_app/core/utils/currency_formatter.dart';
import '../../../services/chat_service.dart';
import '../../../services/gemini_service.dart';
import 'contract_provider.dart';
import '../assets/manage_assets_page.dart';


class CreateContractPage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final Map<String, dynamic> houseData;
  final Map<String, dynamic> roomData;
  final String? contractId;
  final Map<String, dynamic>? initialContractData;

  const CreateContractPage({
    super.key,
    required this.houseId,
    required this.roomId,
    required this.houseData,
    required this.roomData,
    this.contractId,
    this.initialContractData,
  });

  @override
  State<CreateContractPage> createState() => _CreateContractPageState();
}

class _CreateContractPageState extends State<CreateContractPage> {
  final _formKey = GlobalKey<FormState>();

  // Section 1
  String _selectedDuration = '6 Tháng';
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  // Section 2
  final _membersCtrl = TextEditingController(text: '1');
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _useApp = false;

  // Extra Info Section
  bool _showExtraInfo = false;
  final _birthDateCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _issuePlaceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'Nam';

  // Section 3
  final _rentPriceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _paymentCycleCtrl = TextEditingController(text: '1');
  final _billingDateCtrl = TextEditingController(); // e.g. "Ngày 1"
  String _contractTemplate = 'Mẫu mặc định';

  // Section 4
  final _electricPriceCtrl = TextEditingController();
  final _waterPriceCtrl = TextEditingController();

  // Section 6
  List<String> _imageUrls = []; // Dummy list for images

  bool _isSubmitting = false;

  Future<void> _checkActiveDeposit() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('deposits')
          .where('roomId', isEqualTo: widget.roomId)
          .where('status', isEqualTo: 'Active')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (mounted) {
          setState(() {
            _nameCtrl.text = data['tenantName'] ?? '';
            _phoneCtrl.text = data['phoneNumber'] ?? '';
            if (data['depositAmount'] != null) {
              _depositCtrl.text = _formatNumber(data['depositAmount'].toString());
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra cọc giữ chỗ: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if any
    _checkActiveDeposit();
    
    // Pre-fill rent/electric/water price
    if (widget.roomData['price'] != null) {
      _rentPriceCtrl.text = _formatNumber(widget.roomData['price'].toString());
    }
    _electricPriceCtrl.text = _formatNumber((widget.roomData['electricityPrice'] ?? widget.houseData['electricityPrice'] ?? 3500).toString());
    _waterPriceCtrl.text = _formatNumber((widget.roomData['waterPrice'] ?? widget.houseData['waterPrice'] ?? 20000).toString());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialContractData != null && widget.initialContractData!['assets'] != null) {
        final assetsList = widget.initialContractData!['assets'] as List<dynamic>;
        final parsedAssets = assetsList.map((a) {
          if (a is Map) {
            return ContractAsset(
              assetId: a['assetId'],
              assetName: a['assetName'] ?? '',
              iconTag: a['iconTag'] ?? 'category',
              value: (a['value'] ?? 0).toDouble(),
              importPrice: (a['importPrice'] ?? 0).toDouble(),
              quantity: a['quantity'] ?? 1,
              supplier: a['supplier'] ?? '',
              unit: a['unit'] ?? 'Cái',
              status: a['status'] ?? 'Bình thường',
            );
          }
          return null;
        }).where((e) => e != null).cast<ContractAsset>().toList();
        Provider.of<ContractProvider>(context, listen: false).updateAssets(parsedAssets);
      } else {
        Provider.of<ContractProvider>(context, listen: false).updateAssets([]);
      }
    });

    if (widget.initialContractData != null) {
      final initial = widget.initialContractData!;
      _selectedDuration = initial['duration'] ?? '6 Tháng';
      _startDateCtrl.text = initial['startDate'] ?? '';
      _endDateCtrl.text = initial['endDate'] ?? '';
      _membersCtrl.text = (initial['totalMembers'] ?? 1).toString();
      _nameCtrl.text = initial['tenantName'] ?? '';
      _phoneCtrl.text = initial['phoneNumber'] ?? '';
      _useApp = initial['useApp'] ?? false;
      _rentPriceCtrl.text = _formatNumber((initial['rentPrice'] ?? 0).toString());
      _depositCtrl.text = _formatNumber((initial['depositAmount'] ?? 0).toString());
      _paymentCycleCtrl.text = (initial['paymentCycle'] ?? 1).toString();
      _billingDateCtrl.text = initial['billingDate'] ?? '';
      _contractTemplate = initial['contractTemplate'] ?? 'Mẫu mặc định';
      _electricPriceCtrl.text = _formatNumber((initial['electricityPrice'] ?? 0).toString());
      _waterPriceCtrl.text = _formatNumber((initial['waterPrice'] ?? 0).toString());
      
      _birthDateCtrl.text = initial['birthYear'] ?? '';
      _cccdCtrl.text = initial['cccd'] ?? '';
      _issueDateCtrl.text = initial['issueDate'] ?? '';
      _issuePlaceCtrl.text = initial['issuePlace'] ?? '';
      _addressCtrl.text = initial['address'] ?? '';
      _gender = initial['gender'] ?? 'Nam';
    } else {
      _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _updateEndDate();
      
      // Auto check useApp if autoCreateAccount is true in house settings
      final settings = widget.houseData['tenantAppSettings'] as Map<String, dynamic>?;
      if (settings != null && settings['autoCreateAccount'] == true) {
        _useApp = true;
      }
    }
  }

  void _updateEndDate() {
    try {
      final parts = _startDateCtrl.text.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        DateTime startDate = DateTime(year, month, day);
        
        int monthsToAdd = 0;
        if (_selectedDuration.contains('Tháng')) {
          monthsToAdd = int.parse(_selectedDuration.split(' ')[0]);
        } else if (_selectedDuration.contains('Năm')) {
          monthsToAdd = int.parse(_selectedDuration.split(' ')[0]) * 12;
        }

        DateTime endDate = DateTime(startDate.year, startDate.month + monthsToAdd, startDate.day);
        _endDateCtrl.text = DateFormat('dd/MM/yyyy').format(endDate);
      }
    } catch (e) {
      // Do nothing on parse error
    }
  }

  String _formatNumber(String val) {
    if (val.isEmpty) return '';
    final numVal = double.tryParse(val) ?? 0;
    return NumberFormat.decimalPattern('vi_VN').format(numVal);
  }

  double _parseCurrency(String val) {
    return double.tryParse(val.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  Widget _buildScanBanner() {
    return InkWell(
      onTap: _showScanOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xFFFFF9E6),
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
                  Text("Bạn đã có sẵn hợp đồng?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
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

  Future<void> _showScanOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Chọn phương thức tải lên", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Chụp ảnh hợp đồng/CCCD"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("Chọn ảnh từ thư viện"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Chọn file PDF"),
              onTap: () {
                Navigator.pop(context);
                _pickPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      await _processWithGemini(bytes, 'image/jpeg');
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final bytes = result.files.first.bytes;
      if (bytes != null) {
        await _processWithGemini(bytes, 'application/pdf');
      }
    }
  }

  Future<void> _processWithGemini(Uint8List bytes, String mimeType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await GeminiService().parseContractDocument(bytes, mimeType);
      
      if (mounted) {
        setState(() {
          if (data['tenantName']?.toString().isNotEmpty == true) _nameCtrl.text = data['tenantName'].toString();
          if (data['phoneNumber']?.toString().isNotEmpty == true) _phoneCtrl.text = data['phoneNumber'].toString();
          if (data['cccd']?.toString().isNotEmpty == true) {
            _cccdCtrl.text = data['cccd'].toString();
            _showExtraInfo = true;
          }
          if (data['birthYear']?.toString().isNotEmpty == true) _birthDateCtrl.text = data['birthYear'].toString();
          if (data['issueDate']?.toString().isNotEmpty == true) _issueDateCtrl.text = data['issueDate'].toString();
          if (data['issuePlace']?.toString().isNotEmpty == true) _issuePlaceCtrl.text = data['issuePlace'].toString();
          if (data['address']?.toString().isNotEmpty == true) _addressCtrl.text = data['address'].toString();
          if (data['gender']?.toString().isNotEmpty == true) _gender = data['gender'].toString();

          if (data['duration']?.toString().isNotEmpty == true) {
            final dur = data['duration'].toString();
            if (['1 Tháng', '3 Tháng', '6 Tháng', '1 Năm', '2 Năm'].contains(dur)) {
              _selectedDuration = dur;
            }
          }
          if (data['startDate']?.toString().isNotEmpty == true) {
            _startDateCtrl.text = data['startDate'].toString();
            _updateEndDate();
          }
          if (data['rentPrice'] != null) _rentPriceCtrl.text = _formatNumber(data['rentPrice'].toString());
          if (data['depositAmount'] != null) _depositCtrl.text = _formatNumber(data['depositAmount'].toString());
          if (data['billingDate']?.toString().isNotEmpty == true) _billingDateCtrl.text = data['billingDate'].toString();
          if (data['electricityPrice'] != null) _electricPriceCtrl.text = _formatNumber(data['electricityPrice'].toString());
          if (data['waterPrice'] != null) _waterPriceCtrl.text = _formatNumber(data['waterPrice'].toString());
        });
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trích xuất thông tin thành công!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi xử lý: $e")));
      }
    }
  }

  Future<void> _submitContract() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập ngày vào ở")));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final assets = Provider.of<ContractProvider>(context, listen: false).assets;

      final contractData = {
        'roomId': widget.roomId,
        'roomName': widget.roomData['roomName'] ?? '',
        'floor': widget.roomData['floor'],
        'houseId': widget.houseId,
        'startDate': _startDateCtrl.text,
        'endDate': _endDateCtrl.text,
        'duration': _selectedDuration,
        'tenantName': _nameCtrl.text,
        'phoneNumber': _phoneCtrl.text,
        'totalMembers': int.tryParse(_membersCtrl.text) ?? 1,
        'useApp': _useApp,
        'rentPrice': _parseCurrency(_rentPriceCtrl.text),
        'depositAmount': _parseCurrency(_depositCtrl.text),
        'paymentCycle': int.tryParse(_paymentCycleCtrl.text) ?? 1,
        'billingDate': _billingDateCtrl.text,
        'contractTemplate': _contractTemplate,
        'electricityPrice': _parseCurrency(_electricPriceCtrl.text),
        'waterPrice': _parseCurrency(_waterPriceCtrl.text),
        'birthYear': _birthDateCtrl.text,
        'gender': _gender,
        'cccd': _cccdCtrl.text,
        'issueDate': _issueDateCtrl.text,
        'issuePlace': _issuePlaceCtrl.text,
        'address': _addressCtrl.text,
        'assets': assets.map((a) => a.toMap()).toList(),
        'idCardImages': _imageUrls,
        'status': 'Active',
      };

      if (widget.contractId == null) {
        contractData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (widget.contractId == null) {
        // Create new contract
        final activeContracts = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .where('roomId', isEqualTo: widget.roomId)
            .where('status', isEqualTo: 'Active')
            .get();

        if (activeContracts.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phòng này đã có hợp đồng đang hoạt động!")));
            setState(() => _isSubmitting = false);
          }
          return;
        }

        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .add(contractData);

        await FirebaseFirestore.instance
            .collection('houses').doc(widget.houseId)
            .collection('rooms').doc(widget.roomId)
            .update({
        'status': 'Đã thuê',
        'tenantName': _nameCtrl.text.trim(),
        'tenantPhone': _phoneCtrl.text.trim(),
        'contractStartDate': _startDateCtrl.text,
        'contractEndDate': _endDateCtrl.text,
        'useApp': _useApp,
        'rentPrice': _parseCurrency(_rentPriceCtrl.text),
        'depositAmount': _parseCurrency(_depositCtrl.text),
        'totalMembers': int.tryParse(_membersCtrl.text) ?? 1,
        'contractSigned': false,
      });

        final roomName = widget.roomData['roomName'] ?? 'Phòng mới';
        await ChatService().createNewChatRoom(
          roomName, 
          userId: FirebaseAuth.instance.currentUser?.uid,
          houseId: widget.houseId,
          roomId: widget.roomId,
        );

        // Auto create tenant account if useApp is checked
        if (_useApp) {
          await _createTenantAccount();
        }
      } else {
        // Update existing contract
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(widget.contractId)
            .update(contractData);
      }

      if (mounted) {
        if (_useApp) {
          // Nếu chọn sử dụng app/zalo, hỏi để chuyển sang Zalo kết nối luôn
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Kết nối Zalo'),
              content: Text('Hợp đồng đã lập thành công. Bạn có muốn kết nối Zalo cho khách ${_nameCtrl.text} ngay bây giờ không?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                    Navigator.pop(context); // Trở về màn hình trước
                  },
                  child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final phone = _phoneCtrl.text.trim();
                    final connectText = "Ketnoi $phone";
                    
                    // Copy vào clipboard để khách dễ dán
                    await Clipboard.setData(ClipboardData(text: connectText));
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã copy: "$connectText". Hãy dán vào Zalo!'))
                      );
                    }

                    final url = Uri.parse("https://zalo.me/389808064785934940?text=Ketnoi%20$phone");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Kết nối ngay', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A651))),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.contractId == null ? "Lập hợp đồng thành công!" : "Cập nhật thành công!")));
          Navigator.pop(context); // Trở về màn hình trước
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createTenantAccount() async {
    FirebaseApp? tempApp;
    try {
      final landlordUid = FirebaseAuth.instance.currentUser?.uid;
      if (landlordUid == null) return;

      final settings = widget.houseData['tenantAppSettings'] as Map<String, dynamic>?;
      final defaultPassword = settings?['defaultPassword'] ?? "lozido123";
      final phoneNumber = _phoneCtrl.text.trim();

      if (phoneNumber.isEmpty) return;

      // 1. Create Firebase Auth account using a secondary instance
      // This prevents the current landlord user from being logged out
      final String email = '$phoneNumber@lozido.com';
      String uid = '';
      
      try {
        tempApp = await Firebase.initializeApp(
          name: 'TenantAccountCreator_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );
        
        final auth = FirebaseAuth.instanceFor(app: tempApp);
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: defaultPassword,
        );
        uid = userCredential.user?.uid ?? '';
      } catch (e) {
        // If already exists, we might still want to update the Firestore doc
        debugPrint("Auth account might already exist or error occurred: $e");
      }

      // 2. Create/Update account in root collection: tenants/{phoneNumber}
      await FirebaseFirestore.instance
          .collection('tenants')
          .doc(phoneNumber)
          .set({
        'name': _nameCtrl.text.trim(),
        'phoneNumber': phoneNumber,
        'role': 'Tenant',
        'password': defaultPassword,
        'uid': uid, // Store the UID if we managed to create it
        'createdAt': FieldValue.serverTimestamp(),
        'houseId': widget.houseId,
        'roomId': widget.roomId,
        'email': email,
        'userId': landlordUid,
        'birthYear': _birthDateCtrl.text,
        'gender': _gender,
        'cccd': _cccdCtrl.text,
        'issueDate': _issueDateCtrl.text,
        'issuePlace': _issuePlaceCtrl.text,
        'address': _addressCtrl.text,
      }, SetOptions(merge: true));

      debugPrint("Đã tự động tạo tài khoản tenant cho $phoneNumber");
    } catch (e) {
      debugPrint("Lỗi khi tạo tài khoản tenant: $e");
    } finally {
      // Clean up the temporary Firebase App instance
      if (tempApp != null) {
        await tempApp.delete();
      }
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
        title: Text(
          widget.contractId != null 
            ? 'Chỉnh sửa hợp đồng ${widget.roomData['name'] ?? widget.roomData['roomName'] ?? ''}'
            : 'Thêm hợp đồng mới',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.contractId == null) _buildScanBanner(),
              _buildSection1(),
              const SizedBox(height: 8),
              _buildSection2(),
              const SizedBox(height: 8),
              _buildSection3(),
              const SizedBox(height: 8),
              _buildSection4(),
              const SizedBox(height: 8),
              _buildSection5(),
              const SizedBox(height: 8),
              _buildSection6(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSubmitting ? null : _submitContract,
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text(
                    widget.contractId != null ? "Cập nhật hợp đồng" : "Thêm hợp đồng mới", 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00A651),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, bool isNumber = false, Widget? suffix, String? hint, List<TextInputFormatter>? formatters, Function(String)? onChanged}) {
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: isRequired ? (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập' : null : null,
          inputFormatters: formatters,
          onChanged: onChanged,
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
            suffixIcon: suffix,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSection1() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Thông tin thời hạn hợp đồng", "Thiết lập thời hạn cho hợp đồng mới", Icons.numbers),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thời hạn hợp đồng", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDuration,
                    isExpanded: true,
                    items: ['1 Tháng', '3 Tháng', '6 Tháng', '1 Năm', '2 Năm'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                         _selectedDuration = v!;
                         _updateEndDate();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField("Ngày vào ở", _startDateCtrl, isRequired: true, hint: "dd/MM/yyyy", onChanged: (v) => _updateEndDate()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField("Ngày kết thúc", _endDateCtrl, hint: "dd/MM/yyyy"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Thông tin khách thuê", "Quét mã QR thẻ căn cước, khách cũ.", Icons.numbers),
          const SizedBox(height: 16),
          _buildTextField("Tổng số thành viên", _membersCtrl, isRequired: true, isNumber: true, suffix: const Padding(padding: EdgeInsets.all(12), child: Text("Người", style: TextStyle(color: Colors.black54)))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Tên khách", _nameCtrl, isRequired: true, hint: "Tên khách")),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField("SĐT khách (ZALO)", _phoneCtrl, isRequired: true, isNumber: true, hint: "SĐT khách")),
            ],
          ),
          const SizedBox(height: 8),
          const Text("* Nhập SĐT ZALO hệ thống sẽ TỰ ĐỘNG gửi hóa đơn hàng tháng cho khách", style: TextStyle(color: Colors.deepOrange, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              border: Border.all(color: const Color(0xFF00A651).withOpacity(0.5)),
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
                      Text("Sử dụng APP - Dành cho khách thuê", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500, fontSize: 13)),
                      Text("Gửi hóa đơn tự động cho khách, hợp đồng online vv...", style: TextStyle(color: Colors.black54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _showExtraInfo = !_showExtraInfo;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_showExtraInfo ? Icons.unfold_less : Icons.unfold_more, size: 16, color: Colors.black87),
                    const SizedBox(width: 8),
                    const Text("Thông tin khác của khách", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ),
          if (_showExtraInfo) ...[
            const SizedBox(height: 16),
            _buildTextField("Ngày sinh / Năm sinh", _birthDateCtrl, hint: "dd/MM/yyyy"),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Giới tính", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _gender = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField("Thẻ CCCD", _cccdCtrl, hint: "Nhập định danh khách", suffix: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.qr_code, color: Colors.deepOrange, size: 24))),
            const SizedBox(height: 16),
            _buildTextField("Địa chỉ thường trú", _addressCtrl, hint: "Nhập địa chỉ thường trú"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField("Ngày cấp", _issueDateCtrl, hint: "dd/MM/yyyy")),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField("Nơi cấp", _issuePlaceCtrl, hint: "Nơi cấp")),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection3() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Thông tin giá trị hợp đồng", "Thiết lập giá thuê, mẫu hợp đồng", Icons.numbers),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Giá thuê", _rentPriceCtrl, isRequired: true, isNumber: true, formatters: [CurrencyInputFormatter()], suffix: _suffixDong())),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField("Mức giá cọc hợp đồng", _depositCtrl, isNumber: true, formatters: [CurrencyInputFormatter()], suffix: _suffixDong())),
            ],
          ),
          const SizedBox(height: 10),
          const Text("* CHÚ Ý: Sau khi làm hợp đồng bạn phải lập \"Hóa đơn tháng đầu tiên\" để thu tiền thuê và tiền cọc", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField("Chu kỳ thu tiền", _paymentCycleCtrl, isRequired: true, isNumber: true, suffix: Container(
                  width: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
                  child: const Text("tháng", style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold)),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField("Ngày làm hóa đơn (Thu tiền)", _billingDateCtrl, isRequired: true, hint: "Ngày thu")),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(text: const TextSpan(text: 'Mẫu hợp đồng', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13), children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))])),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_contractTemplate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Icon(Icons.close, size: 16, color: Colors.black54),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("* Bạn có thể vào \"phiên bản máy tính\" để chỉnh sửa mẫu văn bản hợp đồng theo ý bạn", style: TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _suffixDong() {
    return Container(
      width: 40,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text("đ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSection4() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Dịch vụ sử dụng cho hợp đồng này", "Tiền điện, nước, rác, wifi...", Icons.numbers),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Tiền điện", _electricPriceCtrl, isNumber: true, formatters: [CurrencyInputFormatter()], suffix: const Padding(padding: EdgeInsets.all(12), child: Text("đ/KWh", style: TextStyle(color: Colors.black54, fontSize: 12))))),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField("Tiền nước", _waterPriceCtrl, isNumber: true, formatters: [CurrencyInputFormatter()], suffix: const Padding(padding: EdgeInsets.all(12), child: Text("đ/Khối", style: TextStyle(color: Colors.black54, fontSize: 12))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection5() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Quản lý tài sản (nội thất)", "Bạn có muốn thêm bớt các tài sản phòng sử dụng?", Icons.numbers),
          const SizedBox(height: 16),
          Consumer<ContractProvider>(
            builder: (context, provider, child) {
              if (provider.assets.isEmpty) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAssetIcon(Icons.chair, Colors.deepOrange.shade100, Colors.deepOrange),
                        const SizedBox(width: 8),
                        _buildAssetIcon(Icons.delete, Colors.blue.shade100, Colors.blue),
                        const SizedBox(width: 8),
                        _buildAssetIcon(Icons.table_restaurant, Colors.purple.shade100, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Chưa có tài sản nào để quản lý...", style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                );
              } else {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.assets.map((a) {
                    return Chip(
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide(color: Colors.green.shade200),
                      label: Text(a.assetName, style: const TextStyle(color: Colors.black87)),
                      avatar: const Icon(Icons.check_circle, color: Color(0xFF00A651), size: 16),
                    );
                  }).toList(),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final provider = Provider.of<ContractProvider>(context, listen: false);
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: provider,
                      child: ManageAssetsPage(houseId: widget.houseId),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 18, color: Colors.black87),
              label: const Text("Chỉnh sửa tài sản", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: Colors.grey.shade300),
                backgroundColor: Colors.grey.shade50,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAssetIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  Widget _buildSection6() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Hình ảnh, file chứng từ", "Hình ảnh CCCD, hình ảnh hợp đồng", Icons.numbers),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(Icons.file_upload_outlined, size: 48, color: Colors.green.shade300),
                const SizedBox(height: 8),
                Text("Tôi đã thêm được ${_imageUrls.length} hình ảnh", style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.black87),
                  label: const Text("Chụp ảnh", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18, color: Colors.black87),
                  label: const Text("Thêm từ thư viện", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
