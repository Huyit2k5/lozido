import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _currentStep = 0; // 0: Phone, 1: OTP, 2: Reset Password

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _otpFocusNode = FocusNode();

  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;
  String _verificationId = '';
  ConfirmationResult? _confirmationResult;


  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Done - navigate to login
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _sendOtp() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError("Vui lòng nhập số điện thoại");
      return;
    }
    setState(() => _isLoading = true);

    // Convert Android VN phone format 098 -> +8498
    if (phone.startsWith('0')) {
      phone = '+84${phone.substring(1)}';
    }

    try {
      // Dùng signInWithPhoneNumber hỗ trợ đa nền tảng (cả Web) tốt hơn
      ConfirmationResult result = await FirebaseAuth.instance.signInWithPhoneNumber(phone);
      
      setState(() {
        _confirmationResult = result;
        _isLoading = false;
        _currentStep = 1; // go to otp step
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Lỗi xác thực số điện thoại: $e");
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) {
      _showError("Vui lòng nhập đủ 6 số OTP");
      return;
    }
    setState(() => _isLoading = true);

    try {
      if (_confirmationResult != null) {
        await _confirmationResult!.confirm(_otpController.text);
      } else {
        // Fallback for native verifyPhoneNumber if we switch back
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _otpController.text,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      setState(() {
        _isLoading = false;
        _currentStep = 2; // go to password step
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Mã OTP không hợp lệ hoặc lỗi mạng");
    }
  }

  void _resetPassword() async {
    String newPass = _newPasswordController.text;
    String confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty || newPass.length < 8) {
      _showError("Mật khẩu mới phải từ 8 ký tự trở lên");
      return;
    }
    if (newPass != confirmPass) {
      _showError("Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPass);

        // Remove the updateEmail workaround due to method deprecation in newer
        // firebase_auth versions and 'email-already-in-use' block.


        // Log out phone auth instance and return to login
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _isLoading = false);
        _showError("Không tìm thấy phiên đăng nhập");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Lỗi cập nhật mật khẩu: ${e.toString()}");
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      // Go back to login
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: _previousStep,
          ),
        ),
        title: const Text(
          "Quên mật khẩu",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    if (_currentStep == 0) _buildPhoneStep(),
                    if (_currentStep == 1) _buildOtpStep(),
                    if (_currentStep == 2) _buildResetPasswordStep(),
                  ],
                ),
              ),
            ),
            _buildFooterText(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
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
          const Text(
            "Quản lý NHÀ CHO THUÊ",
            style: TextStyle(
              color: Color(0xFF28A745),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1: PHONE =================
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          hint: "Nhập số điện thoại",
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE67E22), // Orange warning color
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    children: [
                      TextSpan(text: "Chú ý: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              "Hãy chắc chắn số điện thoại của bạn nhập là đúng. Hệ thống sẽ gửi mã xác nhận qua số điện thoại này để xác minh trước khi bạn thực yêu cầu đổi mật khẩu mới"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildMainButton("Yêu cầu đổi mật khẩu", _sendOtp),
        const SizedBox(height: 15),
        _buildSecondaryButton("Quay lại đăng nhập", () {
          Navigator.pop(context);
        }),
      ],
    );
  }

  // ================= STEP 2: OTP =================
  Widget _buildOtpStep() {
    String phoneText = _phoneController.text;
    if (phoneText.isEmpty) phoneText = "của bạn";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          "Vui lòng nhập mã OTP đã được gửi đến số $phoneText để xác minh tài khoản của bạn.",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        _buildCustomOtpInput(),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            "Gửi lại mã (55s)",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildMainButton("Xác nhận mã", _verifyOtp),
        const SizedBox(height: 15),
        _buildSecondaryButton("Quay lại", _previousStep),
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
                    color: isFocused ? const Color(0xFF28A745) : Colors.grey.shade300,
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

  // ================= STEP 3: RESET MẬT KHẨU =================
  Widget _buildResetPasswordStep() {
    bool isMatch = _newPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Đặt lại mật khẩu",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Tạo mật khẩu mới cho tài khoản của bạn. Mật khẩu phải bảo mật và khó đoán.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 25),
        _buildPasswordField(
          hint: "Mật khẩu mới",
          obscure: _isObscureNew,
          controller: _newPasswordController,
          toggle: () => setState(() => _isObscureNew = !_isObscureNew),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 15),
        _buildPasswordField(
          hint: "Xác nhận mật khẩu mới",
          obscure: _isObscureConfirm,
          controller: _confirmPasswordController,
          toggle: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
          onChanged: (val) => setState(() {}),
        ),
        if (isMatch)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF28A745), size: 16),
                SizedBox(width: 8),
                Text(
                  "Mật khẩu khớp",
                  style: TextStyle(
                    color: Color(0xFF28A745),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 30),
        _buildMainButton("Hoàn tất và Đăng nhập", _resetPassword),
        const SizedBox(height: 15),
        _buildSecondaryButton("Quay lại", _previousStep),
      ],
    );
  }

  // ================= UI HELPERS =================

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF28A745), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required bool obscure,
    required TextEditingController controller,
    required VoidCallback toggle,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF28A745), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
            size: 22,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
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
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
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
