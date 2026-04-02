import 'package:flutter/material.dart';

class ChatSettingsPage extends StatelessWidget {
  final String roomName;

  const ChatSettingsPage({
    super.key,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Cài đặt nhóm hội thoại',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header Info
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFFF5722), // Orange/Red
                    child: Icon(Icons.home, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    roomName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trao đổi trong $roomName',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.person_add_alt_1_outlined, 'Thêm\nthành viên'),
                _buildActionButton(Icons.notifications_off_outlined, 'Tắt\nthông báo'),
                _buildActionButton(Icons.logout, 'Rời khỏi\nchat', color: Colors.orange[800]),
              ],
            ),
            const SizedBox(height: 32),
            // Settings List Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    label: 'Nhận thông báo',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Đang bật', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16),
                  _buildSettingsItem(
                    label: 'Pin hội thoại',
                    trailing: const Text('Đã ghim', style: TextStyle(color: Colors.black54)),
                  ),
                  const Divider(height: 1, indent: 16),
                  _buildSettingsItem(
                    label: 'Tổng số thành viên',
                    trailing: const Text(
                      'Xem 2 Thành viên',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  const Divider(height: 1, indent: 16),
                  _buildSettingsItem(
                    label: 'Hình nền',
                    trailing: const Text('Không có', style: TextStyle(color: Colors.black54)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {Color? color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: color ?? Colors.black87, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({required String label, required Widget trailing}) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: trailing,
      onTap: () {},
    );
  }
}
