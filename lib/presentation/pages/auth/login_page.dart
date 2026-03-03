import 'package:flutter/material.dart';
import 'package:lozido_app/presentation/pages/auth/register_page.dart';
import '../../widgets/form_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  bool _isConfirmObscure = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
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

              // Field: Số điện thoại
              CustomLabel(label: "Số điện thoại", isRequired: true),
              CustomTextField(hint: "Nhập số điện thoại của bạn"),

              // Field: Mật khẩu
              CustomLabel(label: "Mật khẩu", isRequired: true),
              CustomTextField(
                hint: "Nhập đúng SĐT của bạn",
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 20),

              // Nút đăng nhập tài khoản
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
                    "Đăng nhập tài khoản",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              //
              // SizedBox(height: 15,),
              //
              // //Nút đăng nhập bằng Zalo
              // SizedBox(
              //   width: double.infinity,
              //   height: 50,
              //   child: ElevatedButton(
              //     onPressed: () {},
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.blue,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: Text(
              //       "Đăng nhập tài khoản bằng Zalo",
              //       style: TextStyle(fontSize: 16, color: Colors.white),
              //     ),
              //   ),
              // ),

              //Phần tạo tài khoản và quên tài khoản
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterScreen(), // Gọi class màn hình Đăng ký của bạn ở đây
                              ),
                            );
                          },
                          child: Text(
                            "Tạo tài khoản?",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Quên tài khoản?",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          "Hỗ trợ việc đăng nhập",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    SupportOption(
                      icon: Icons.phone,
                      text: "Gọi điện trực tiếp (sẵn sàng)",
                    ),
                    Divider(),
                    SupportOption(
                      icon: Icons.chat_bubble,
                      text: "Chat/Gọi điện qua Zalo (sẵn sàng)",
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
