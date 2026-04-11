import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandlordInfoPage extends StatefulWidget {
  const LandlordInfoPage({super.key});

  @override
  State<LandlordInfoPage> createState() => _LandlordInfoPageState();
}

class _LandlordInfoPageState extends State<LandlordInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _issuePlaceController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['landlordRepresentativeName'] ?? '';
            _phoneController.text = data['landlordRepresentativePhone'] ?? '';
            _dobController.text = data['landlordDob'] ?? '';
            _jobController.text = data['landlordJob'] ?? '';
            _addressController.text = data['landlordAddress'] ?? '';
            _idCardController.text = data['landlordIdCard'] ?? '';
            _issuePlaceController.text = data['landlordIdIssuePlace'] ?? '';
            _issueDateController.text = data['landlordIdIssueDate'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Error loading landlord info: $e");
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập các thông tin bắt buộc'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'landlordRepresentativeName': _nameController.text.trim(),
          'landlordRepresentativePhone': _phoneController.text.trim(),
          'landlordDob': _dobController.text.trim(),
          'landlordJob': _jobController.text.trim(),
          'landlordAddress': _addressController.text.trim(),
          'landlordIdCard': _idCardController.text.trim(),
          'landlordIdIssuePlace': _issuePlaceController.text.trim(),
          'landlordIdIssueDate': _issueDateController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lưu thông tin thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _jobController.dispose();
    _addressController.dispose();
    _idCardController.dispose();
    _issuePlaceController.dispose();
    _issueDateController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, String? hintText, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            children: [
              if (isRequired)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: suffix,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: const Text(
          "Thông tin đại diện của tòa nhà",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner notification
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F0),
                            border: Border.all(color: const Color(0xFFFF9E6E)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFFF6D00), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                                    children: [
                                      TextSpan(text: 'Các thông tin này sẽ được hệ thống tạo ra các văn bản tự động như '),
                                      TextSpan(
                                        text: 'Văn bản hợp đồng, văn bản thông tin nhân khẩu...',
                                        style: TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form fields
                        Row(
                          children: [
                            Expanded(child: _buildTextField("Tên người đại diện", _nameController, isRequired: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField("Số điện thoại", _phoneController, isRequired: true)),
                          ],
                        ),
                        _buildTextField("Ngày sinh", _dobController, isRequired: true, hintText: "dd/MM/yyyy"),
                        _buildTextField("Nghề nghiệp", _jobController, isRequired: true),
                        _buildTextField("Địa chỉ", _addressController, isRequired: true),
                        _buildTextField(
                          "Thẻ CCCD",
                          _idCardController,
                          hintText: "Ví dụ: 001304207098 hoặc 2123234",
                          suffix: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.sync, color: Color(0xFF00A651), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Passport",
                                  style: TextStyle(color: Color(0xFF00A651), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField("Nơi cấp", _issuePlaceController, isRequired: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField("Ngày cấp", _issueDateController, isRequired: true, hintText: "dd/MM/yyyy")),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.black, size: 20),
                            label: const Text("Đóng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F4F8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.edit, color: Colors.white, size: 20),
                            label: Text(
                              _isSaving ? "Đang lưu..." : "Lưu thông tin",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A651),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
