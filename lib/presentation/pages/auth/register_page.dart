import 'package:flutter/material.dart';

// void main() => runApp(
//   MaterialApp(home: RegisterScreen(), debugShowCheckedModeBanner: false),
// );

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscure = true;
  bool _isConfirmObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          "Đăng ký tài khoản",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo LOZIDO
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work_rounded,
                          color: Colors.green,
                          size: 40,
                        ), // Thay bằng Image.asset nếu có logo
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
                    Text(
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
            _buildTextField("Nhập tên của bạn"),

            // Field: Số điện thoại
            _buildLabel("SĐT (Dùng đăng nhập)"),
            _buildTextField(
              "Nhập đúng SĐT của bạn",
              keyboardType: TextInputType.phone,
            ),

            // Row: Mật khẩu & Xác nhận mật khẩu
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Mật khẩu"),
                      _buildPasswordField("Nhập mật khẩu", _isObscure, () {
                        setState(() => _isObscure = !_isObscure);
                      }),
                    ],
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Xác nhận mật khẩu"),
                      _buildPasswordField(
                        "Nhập mật khẩu",
                        _isConfirmObscure,
                        () {
                          setState(
                            () => _isConfirmObscure = !_isConfirmObscure,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Ghi chú mật khẩu
            Container(
              margin: EdgeInsets.only(top: 15),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildRequirement("Mật khẩu phải lớn hơn 8 ký tự"),
                  SizedBox(height: 5),
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
                  text: TextSpan(
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00A651),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Tạo tài khoản mới",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            // Nút Đăng nhập
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "Bạn đã có tài khoản, Đăng nhập?",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),

            // Phần hỗ trợ
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
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
                  SizedBox(height: 15),
                  _buildSupportOption(
                    Icons.phone,
                    "Gọi điện trực tiếp (sẵn sàng)",
                  ),
                  Divider(),
                  _buildSupportOption(
                    Icons.chat_bubble,
                    "Chat/Gọi điện qua Zalo (sẵn sàng)",
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Các Widget bổ trợ để code sạch hơn ---

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: " *",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  Widget _buildPasswordField(String hint, bool obscure, VoidCallback toggle) {
    return TextFormField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 15),
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
        Icon(Icons.check, color: Colors.green, size: 16),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSupportOption(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: Colors.green),
        Text(text, style: TextStyle(fontSize: 13)),
      ],
    );
  }
}
