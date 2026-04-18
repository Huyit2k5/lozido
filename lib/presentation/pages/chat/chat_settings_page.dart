import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatSettingsPage extends StatelessWidget {
  final String roomName;
  final String roomId;

  const ChatSettingsPage({
    super.key,
    required this.roomName,
    required this.roomId,
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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: roomName.toLowerCase() == 'lozido cskh' ? Colors.blue : const Color(0xFFFF5722),
                    child: Icon(
                      roomName.toLowerCase() == 'lozido cskh' ? Icons.smart_toy : Icons.home, 
                      color: Colors.white, 
                      size: 40
                    ),
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
                    trailing: StreamBuilder<int>(
                      stream: FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(roomId)
                          .snapshots()
                          .map((doc) => (doc.data()?['memberCount'] ?? 0) as int),
                      builder: (context, snap) {
                        final count = snap.data ?? 0;
                        return Text(
                          'Xem $count Thành viên',
                          style: const TextStyle(color: Colors.blueAccent),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 16),
                  _buildSettingsItem(
                    label: 'Hình nền',
                    trailing: const Text('Không có', style: TextStyle(color: Colors.black54)),
                    onTap: () {},
                  ),
                  if (roomName.toLowerCase() == 'lozido cskh') ...[
                    const Divider(height: 1, indent: 16),
                    _buildSettingsItem(
                      label: 'Thêm tài liệu cho Chatbot (PDF)',
                      trailing: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      onTap: () => _uploadPdf(context),
                    ),
                  ],
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

  Widget _buildSettingsItem({required String label, required Widget trailing, VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: trailing,
      onTap: onTap ?? () {},
    );
  }

  Future<void> _uploadPdf(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        String fileName = platformFile.name;

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref();
        final pdfsRef = storageRef.child('pdfs/bot_${DateTime.now().millisecondsSinceEpoch}_$fileName');
        
        if (kIsWeb) {
          // Web environment ALWAYS uses bytes
          await pdfsRef.putData(platformFile.bytes!);
        } else {
          // For mobile, sometimes large files bytes are null depending on the OS picker
          if (platformFile.bytes != null) {
             await pdfsRef.putData(platformFile.bytes!);
          } else if (platformFile.path != null) {
             // We can't import dart:io safely top-level for web, so we skip file upload fallback 
             // but 'withData: true' usually ensures bytes array is valid for PDFs.
             await pdfsRef.putData(await platformFile.xFile.readAsBytes()); // alternative if xFile is supported, or just trust bytes
          }
        }

        // Hide loading dialog
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải tài liệu PDF thành công!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if error occurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải file: $e')),
        );
      }
    }
  }
}
