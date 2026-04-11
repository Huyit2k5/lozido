import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lozido_app/presentation/pages/auth/login_page.dart';
import 'package:lozido_app/presentation/pages/main_screen/main_page.dart';
import 'package:lozido_app/presentation/pages/tenant/tenant_main_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00A651)),
            ),
          );
        }

        final user = authSnapshot.data;

        // Nếu chưa đăng nhập, trả về trang Login
        if (user == null) {
          return const LoginScreen();
        }

        // Tự động sử dụng đăng nhập ẩn danh cho trường hợp cần thiết khác,
        // nhưng nếu đã có tài khoản thực, chúng ta kiểm tra role.
        if (user.isAnonymous) {
             // Tuỳ thuộc quy trình của bạn, nếu ẩn danh xem như đang setup login
             return const LoginScreen();
        }

        // Kiểm tra Role trong Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00A651)),
                ),
              );
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Xử lý mất mạng hoặc xoá user
              return _ErrorScreen(
                message: 'Không thể tìm thấy thông tin tài khoản người dùng',
                onRetry: () => setState(() {}),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            final role = userData?['role'] as String? ?? 'Landlord'; // Nếu null, mặc định chọn Landlord

            if (role == 'Tenant') {
              return const TenantMainPage();
            } else {
              // Landlord hoặc Admin hoặc Default
              return const MainPage();
            }
          },
        );
      },
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                   await FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A651)),
                child: const Text('Đăng nhập lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
