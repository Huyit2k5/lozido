import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/datasources/firebase_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0: Form thông tin, 1: Xác nhận OTP

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FocusNode _otpFocusNode = FocusNode();
  ConfirmationResult? _confirmationResult;

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
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      ConfirmationResult result = await _authService.verifyPhoneForRegistration(
        phoneNumber: _phoneController.text.trim(),
      );

      setState(() {
        _confirmationResult = result;
        _isLoading = false;
        _currentStep = 1; // Chuyển sang bước OTP
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyAndCompleteRegistration() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 số OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_confirmationResult != null) {
        await _authService.completeRegistration(
          confirmationResult: _confirmationResult!,
          smsCode: _otpController.text,
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
        
        // Đăng xuất ra để đảm bảo luồng login sạch sẽ (vì ta vừa dùng phone auth)
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.pop(context); // Trở về trang đăng nhập
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
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
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? "Đăng ký tài khoản" : "Xác nhận OTP",
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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

            if (_currentStep == 0) _buildFormStep(),
            if (_currentStep == 1) _buildOtpStep(),

          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              onPressed: _isLoading ? null : _sendOtp,
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
                      "Đăng ký bằng SĐT",
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
    );
  }

  Widget _buildOtpStep() {
    String phoneText = _phoneController.text;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Xác nhận số điện thoại",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Vui lòng nhập mã OTP đã được gửi đến số $phoneText để xác minh kích hoạt tài khoản.",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        _buildCustomOtpInput(),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyAndCompleteRegistration,
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
                    "Xác nhận kích hoạt",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => setState(() => _currentStep = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Quay lại",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCustomOtpInput() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_otpFocusNode);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden TextField
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                maxLength: 6,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (val) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  counterText: "",
                ),
              ),
            ),
          ),
          // 6 visible boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              String char = "";
              if (_otpController.text.length > index) {
                char = _otpController.text[index];
              }
              bool isFocused = _otpFocusNode.hasFocus && _otpController.text.length == index;
               if (index == 5 && _otpController.text.length == 6 && _otpFocusNode.hasFocus) {
                 isFocused = true;
              }

              return Container(
                width: 45,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFocused ? const Color(0xFF00A651) : Colors.grey.shade300,
                    width: isFocused ? 2 : 1,
                  ),
                ),
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              );
            }),
          ),
        ],
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
