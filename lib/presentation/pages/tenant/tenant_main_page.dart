import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lozido_app/presentation/pages/auth/auth_wrapper.dart';

class TenantMainPage extends StatefulWidget {
  const TenantMainPage({super.key});

  @override
  State<TenantMainPage> createState() => _TenantMainPageState();
}

class _TenantMainPageState extends State<TenantMainPage> {
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng Dụng Khách Thuê'),
        backgroundColor: const Color(0xFF00A651),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirm(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.house_outlined, size: 80, color: Color(0xFF00A651)),
            SizedBox(height: 20),
            Text(
              'Giao diện dành cho\nKhách thuê (Tenant)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Các tính năng dành cho khách thuê\nsẽ được cập nhật sau.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirm(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
