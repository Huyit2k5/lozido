import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Không tìm thấy người dùng đang đăng nhập");

      // 1. Re-authenticate
      final email = user.email;
      if (email == null) throw Exception("Tài khoản không có email liên kết");

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Update password
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Đã xảy ra lỗi khi đổi mật khẩu";
      if (e.code == 'wrong-password') {
        message = "Mật khẩu hiện tại không chính xác";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu mới quá yếu";
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          "Đổi mật khẩu hiện tại",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildLogoHeader(),
                const SizedBox(height: 40),
                
                _buildLabel("Xác nhận mật khẩu"),
                _buildPasswordField(
                  hint: "Nhập lại mật khẩu hiện tại",
                  controller: _currentPasswordController,
                  obscure: _isObscureCurrent,
                  toggle: () => setState(() => _isObscureCurrent = !_isObscureCurrent),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Vui lòng nhập mật khẩu hiện tại";
                    return null;
                  },
                ),
                
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Mật khẩu mới"),
                          _buildPasswordField(
                            hint: "Mật khẩu mới",
                            controller: _newPasswordController,
                            obscure: _isObscureNew,
                            toggle: () => setState(() => _isObscureNew = !_isObscureNew),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Nhập mật khẩu mới";
                              if (val.length < 8) return "Tối thiểu 8 ký tự";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Xác nhận mật khẩu mới"),
                          _buildPasswordField(
                            hint: "Xác nhận",
                            controller: _confirmNewPasswordController,
                            obscure: _isObscureConfirm,
                            toggle: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Xác nhận mật khẩu";
                              if (val != _newPasswordController.text) return "Mật khẩu không khớp";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                _buildHintBox(),
                
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work_rounded, color: Color(0xFF28A745), size: 40),
            const SizedBox(width: 8),
            const Text(
              "LOZIDO",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const Text(
          "Quản lý NHÀ CHO THUÊ",
          style: TextStyle(
            color: Color(0xFF28A745),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
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
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.black,
            size: 20,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildHintBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHintRow("Mật khẩu phải lớn hơn 8 ký tự"),
          const SizedBox(height: 4),
          _buildHintRow("Chú ý đến hoa thường"),
        ],
      ),
    );
  }

  Widget _buildHintRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check, color: Color(0xFF28A745), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A651),
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
                "Thay đổi mật khẩu",
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
