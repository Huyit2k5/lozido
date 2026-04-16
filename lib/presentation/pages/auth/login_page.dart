import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/datasources/firebase_auth_service.dart';
import 'auth_wrapper.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isTenantMode = false;
  bool _isLoading = false;

  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      final password = _passwordController.text;

      // Extra verification for Tenants
      if (_isTenantMode) {
        final tenantSnap = await FirebaseFirestore.instance
            .collection('tenants')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        if (tenantSnap.docs.isEmpty) {
          throw Exception('Tài khoản người thuê không tồn tại cho số điện thoại này.');
        }

        final tenantData = tenantSnap.docs.first.data();
        final storedPassword = tenantData['password']?.toString();

        if (storedPassword != password) {
          throw Exception('Mật khẩu người thuê không chính xác.');
        }

        // Use the stored password from tenant document for Firebase Auth login
        // because the Auth account was created with defaultPassword from settings,
        // which may differ from what the user enters.
        final tenantEmail = tenantData['email']?.toString() ?? '$phoneNumber@lozido.com';
        final tenantAuthPassword = storedPassword ?? password;

        await _authService.loginWithPhoneNumber(
          phoneNumber: tenantEmail.replaceAll('@lozido.com', ''),
          password: tenantAuthPassword,
        );
      } else {
        await _authService.loginWithPhoneNumber(
          phoneNumber: phoneNumber,
          password: password,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Let AuthWrapper handle the routing by clearing the stack and navigating back to root
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Hỗ trợ cuộc gọi và Zalo ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thực hiện cuộc gọi trên thiết bị này.')),
      );
    }
  }

  Future<void> _openZalo(String phoneNumber) async {
    // Thông thường link zalo có dạng https://zalo.me/sdt
    final Uri launchUri = Uri.parse("https://zalo.me/$phoneNumber");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng Zalo. Hãy thêm cấu hình theo tài liệu URL Launcher nếu dùng trên thiết bị thật.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                
                _buildLabel("Số điện thoại"),
                _buildInputField(
                  hint: "Nhập số điện thoại",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Vui lòng nhập số điện thoại";
                    if (val.length < 10) return "Số điện thoại không hợp lệ";
                    return null;
                  },
                ),
                
                _buildLabel("Mật khẩu"),
                _buildPasswordField(
                  hint: "Nhập mật khẩu",
                  obscure: _isObscure,
                  controller: _passwordController,
                  toggle: () => setState(() => _isObscure = !_isObscure),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Vui lòng nhập mật khẩu";
                    return null;
                  },
                ),
                
                _buildValidationUI(),
                const SizedBox(height: 20),
                
                _buildMainLoginButton(),
                const SizedBox(height: 15),
                
                _buildTenantLoginButton(),
                const SizedBox(height: 25),
                
                _buildLinksRow(),
                const SizedBox(height: 40),
                
                _buildSupportCard(),
                const SizedBox(height: 30),
                
                _buildFooterText(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Builder Widgets ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_work_rounded,
                color: Color(0xFF28A745),
                size: 50,
              ),
              const SizedBox(width: 8),
              const Text(
                "LOZIDO",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _isTenantMode ? "Tìm trọ - căn hộ" : "Quản lý NHÀ CHO THUÊ",
            style: const TextStyle(
              color: Color(0xFF28A745),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
          children: const [
            TextSpan(
              text: " *",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required bool obscure,
    required TextEditingController controller,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.black,
            size: 22,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildValidationUI() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8EC), // Màu nền xanh sáng
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check, color: Color(0xFF28A745), size: 16),
              SizedBox(width: 8),
              Text("Mật khẩu phải lớn hơn 8 ký tự", style: TextStyle(color: Colors.black87, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: const [
              Icon(Icons.check, color: Color(0xFF28A745), size: 16),
              SizedBox(width: 8),
              Text("Chú ý đến hoa thường", style: TextStyle(color: Colors.black87, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainLoginButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28A745),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "Đăng nhập tài khoản",
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildTenantLoginButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _isTenantMode = !_isTenantMode;
          });
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF0068FF), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTenantMode ? Icons.admin_panel_settings_outlined : Icons.person_outline,
              color: const Color(0xFF0068FF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isTenantMode ? "Đăng nhập dành cho chủ trọ" : "Đăng nhập dành cho người thuê",
              style: const TextStyle(fontSize: 14, color: Color(0xFF0068FF), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            "Tạo tài khoản",
            style: TextStyle(
              color: Color(0xFF0068FF),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF0068FF),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
            );
          },
          child: const Text(
            "Quên tài khoản ?",
            style: TextStyle(
              color: Color(0xFF0068FF),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF0068FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEB5757),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Hỗ trợ việc đăng nhập", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("Chuyên viên luôn sẵn sàng hỗ trợ 24/7", style: TextStyle(fontSize: 11, color: Colors.black87)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          InkWell(
            onTap: () => _makePhoneCall('0987654321'), // Thay thế SĐT sau
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.phone, color: Color(0xFF28A745), size: 20),
                  Expanded(
                    child: Text(
                      "Gọi điện trực tiếp (sẵn sàng)",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          InkWell(
            onTap: () => _openZalo('0987654321'), // SĐT hỗ trợ
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0068FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('Zalo', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const Expanded(
                    child: Text(
                      "Chat/Gọi điện qua Zalo (sẵn sàng)",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterText() {
    return const Center(
      child: Text(
        "Phiên bản: 3.0.6 - Copyright @ quanlytro.me",
        style: TextStyle(color: Colors.black54, fontSize: 11),
      ),
    );
  }
}
