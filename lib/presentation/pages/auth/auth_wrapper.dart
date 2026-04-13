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
        return FutureBuilder<Map<String, dynamic>?>(
          future: _resolveUserRole(user),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00A651)),
                ),
              );
            }

            final userData = userSnapshot.data;
            if (userData == null) {
              // Xử lý mất mạng hoặc xoá user
              return _ErrorScreen(
                message: 'Không thể tìm thấy thông tin tài khoản người dùng',
                onRetry: () => setState(() {}),
              );
            }

            final role = userData['role'] as String? ?? 'Landlord'; // Nếu null, mặc định chọn Landlord

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

  Future<Map<String, dynamic>?> _resolveUserRole(User user) async {
    try {
      // 1. Check top-level users collection first (Landlords)
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }

      // 2. If not found, check for Tenant in sub-collections
      // Try to find by UID first (if they registered directly or were updated)
      try {
        final tenantByUid = await FirebaseFirestore.instance
            .collection('tenants')
            .where('uid', isEqualTo: user.uid)
            .get();
        if (tenantByUid.docs.isNotEmpty) {
          return tenantByUid.docs.first.data();
        }
      } catch (e) {
        debugPrint("Lỗi khi tìm tenant theo UID: $e");
        if (e.toString().contains('failed-precondition')) {
          debugPrint("CẦN TẠO INDEX cho collectionGroup 'tenant'");
        }
      }

      // 3. Try to find by Phone Number (extracted from email or user object)
      String? phoneNumber = user.phoneNumber;
      if (phoneNumber == null && user.email != null && user.email!.endsWith('@lozido.com')) {
        phoneNumber = user.email!.split('@').first;
      }

      if (phoneNumber != null) {
        try {
          final tenantByPhone = await FirebaseFirestore.instance
              .collection('tenants')
              .where('phoneNumber', isEqualTo: phoneNumber)
              .get();
          if (tenantByPhone.docs.isNotEmpty) {
            // Found it! Optionally update the UID if it is missing
            final doc = tenantByPhone.docs.first;
            if (doc.data()['uid'] == null || doc.data()['uid'] == '') {
              await doc.reference.update({'uid': user.uid});
            }
            return doc.data();
          }
        } catch (e) {
          debugPrint("Lỗi khi tìm tenant theo Phone: $e");
           if (e.toString().contains('failed-precondition')) {
            throw Exception('Vui lòng tạo Index cho collectionGroup "tenant" trong Firebase Console.');
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Lỗi phân quyền: $e");
      rethrow; // Let FutureBuilder handle the error if it's an index issue
    }
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
