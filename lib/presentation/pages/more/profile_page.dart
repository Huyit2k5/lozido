import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_profile_page.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mã tài khoản!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: const Text(
                "Bạn có chắc chắn muốn xóa tài khoản vĩnh viễn? Hành động này không thể hoàn tác và tất cả dữ liệu của bạn sẽ bị mất."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Xóa vĩnh viễn", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Xóa dữ liệu trên Firestore (tùy chọn, tùy vào yêu cầu hệ thống)
          // Ở đây ta xóa tài khoản Auth
          await user.delete();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tài khoản đã được xóa vĩnh viễn.'), backgroundColor: Colors.red),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi khi xóa tài khoản: $e. Bạn có thể cần đăng nhập lại trước khi xóa.'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Thêm", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Cá nhân", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> data = {};
          if (snapshot.hasData && snapshot.data!.data() != null) {
            data = snapshot.data!.data() as Map<String, dynamic>;
          }

          final name = data['name'] ?? "Người dùng";
          final email = data['email'] ?? "không có";
          final phone = data['phoneNumber'] ?? "Chưa cập nhật";
          final createdAt = data['createdAt'] != null 
              ? DateFormat('HH:mm:ss d/M/yyyy').format((data['createdAt'] as Timestamp).toDate())
              : "Chưa rõ";
          final customerId = "#${(user?.uid.substring(0, 10) ?? "26OW00012844").toUpperCase()}";

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 70),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(
                                  userId: user.uid,
                                  currentName: name,
                                  currentEmail: email == "không có" ? "" : email,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                        label: const Text("Chỉnh sửa", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Info List
                _buildInfoItem(context, "Mã tài khoản khách hàng", customerId, isCopyable: true),
                _buildInfoItem(
                  context, 
                  "Trạng thái tài khoản", 
                  "Đã xác minh", 
                  trailingWidget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFF00A651), size: 14),
                        SizedBox(width: 4),
                        Text("Đã xác minh", style: TextStyle(color: Color(0xFF00A651), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                _buildInfoItem(context, "Tên", name),
                _buildInfoItem(context, "Số điện thoại", phone),
                _buildInfoItem(context, "Email", email),
                _buildInfoItem(context, "Ngày tham gia", createdAt),
                _buildInfoItem(context, "Đăng nhập lần đầu tiên", "không có"),
                
                const SizedBox(height: 30),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.black87),
                          label: const Text("Đăng xuất tài khoản", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F4F8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Tôi muốn xóa tài khoản", style: TextStyle(color: Colors.black54, fontSize: 14)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleDeleteAccount(context),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          label: const Text("Xóa tài khoản vĩnh viễn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, {bool isCopyable = false, Widget? trailingWidget}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          Row(
            children: [
              if (trailingWidget != null) trailingWidget else Text(
                value,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, value),
                  child: const Icon(Icons.copy, size: 20, color: Colors.black54),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
