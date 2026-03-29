import 'package:flutter/material.dart';
import '../../../data/datasources/firebase_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;

  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerWithPhoneNumber(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Trở về trang đăng nhập
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đăng ký tài khoản",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo LOZIDO
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            color: Colors.green,
                            size: 40,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "LOZIDO",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Quản lý NHÀ CHO THUÊ",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Field: Tên hiển thị
              _buildLabel("Tên (Dùng hiển thị)"),
              _buildTextField(
                hint: "Nhập tên của bạn",
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Vui lòng nhập tên";
                  return null;
                },
              ),

              // Field: Số điện thoại
              _buildLabel("SĐT (Dùng đăng nhập)"),
              _buildTextField(
                hint: "Nhập đúng SĐT của bạn",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Vui lòng nhập SĐT";
                  if (val.length < 10 || val.length > 11) return "SĐT không hợp lệ";
                  return null;
                },
              ),

              // Row: Mật khẩu & Xác nhận mật khẩu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Mật khẩu"),
                        _buildPasswordField(
                          hint: "Nhập mật khẩu",
                          obscure: _isObscure,
                          controller: _passwordController,
                          toggle: () => setState(() => _isObscure = !_isObscure),
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Nhập mật khẩu";
                            if (val.length < 8) return "Quá ngắn";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Xác nhận mật khẩu"),
                        _buildPasswordField(
                          hint: "Nhập mật khẩu",
                          obscure: _isConfirmObscure,
                          controller: _confirmPasswordController,
                          toggle: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Xác nhận mk";
                            if (val != _passwordController.text) return "Không khớp";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Ghi chú mật khẩu
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildRequirement("Mật khẩu phải lớn hơn 8 ký tự"),
                    const SizedBox(height: 5),
                    _buildRequirement("Chú ý đến hoa thường"),
                  ],
                ),
              ),

              // Điều khoản
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: "Khi tạo tài khoản là bạn đã chấp nhận ",
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                      children: [
                        TextSpan(
                          text: "Điều khoản dịch vụ",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: " và "),
                        TextSpan(
                          text: "Chính sách bảo mật",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: " của chúng tôi."),
                      ],
                    ),
                  ),
                ),
              ),

              // Nút Tạo tài khoản
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Tạo tài khoản mới",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              // Nút Đăng nhập
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Bạn đã có tài khoản, Đăng nhập?",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),

              // Phần hỗ trợ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          radius: 10,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Hỗ trợ đăng ký tài khoản",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildSupportOption(
                      Icons.phone,
                      "Gọi điện trực tiếp (sẵn sàng)",
                    ),
                    const Divider(),
                    _buildSupportOption(
                      Icons.chat_bubble,
                      "Chat/Gọi điện qua Zalo (sẵn sàng)",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Các Widget bổ trợ ---

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

  Widget _buildTextField({
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Row(
      children: [
        const Icon(Icons.check, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSupportOption(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: Colors.green),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
