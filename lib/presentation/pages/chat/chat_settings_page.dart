import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatSettingsPage extends StatelessWidget {
  final String roomName;
  final String roomId;
  final bool isTenant;

  const ChatSettingsPage({
    super.key,
    required this.roomName,
    required this.roomId,
    this.isTenant = false,
  });

  bool get isBotRoom => roomName.toLowerCase() == 'lozido cskh';

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
                    backgroundColor: isBotRoom ? Colors.blue : const Color(0xFFFF5722),
                    child: Icon(
                      isBotRoom ? Icons.smart_toy : Icons.home, 
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
                    isBotRoom ? 'Hỗ trợ trực tuyến Lozido' : 'Trao đổi trong $roomName',
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
                if (!isBotRoom)
                  _buildActionButton(Icons.person_add_alt_1_outlined, 'Thêm\nthành viên'),
                _buildActionButton(Icons.notifications_off_outlined, 'Tắt\nthông báo'),
                if (!isBotRoom)
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
                  if (!isBotRoom) ...[
                    const Divider(height: 1, indent: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('chatRooms').doc(roomId).snapshots(),
                        builder: (context, chatRoomSnap) {
                          if (!chatRoomSnap.hasData) return const SizedBox.shrink();
                          final chatRoomData = chatRoomSnap.data!.data() as Map<String, dynamic>? ?? {};
                          final int tenantCount = chatRoomData['memberCount'] ?? 0;
                          final String ownerId = chatRoomData['userId'] ?? '';
                          final String chatRoomName = chatRoomData['roomName'] ?? '';

                          return ExpansionTile(
                            title: const Text('Thành viên nhóm', style: TextStyle(fontSize: 15)),
                            trailing: Text(
                              'Xem ${tenantCount + 1} thành viên',
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              // 1. Fetch Landlord (Owner)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                                builder: (context, ownerSnap) {
                                  String ownerName = 'Đang tải...';
                                  if (ownerSnap.hasData && ownerSnap.data!.exists) {
                                    final data = ownerSnap.data!.data() as Map<String, dynamic>;
                                    ownerName = data['name'] ?? 'Chủ phòng';
                                  }
                                  return _buildMemberTile(ownerName, 'Chủ phòng', isOwner: true);
                                },
                              ),
                              // 2. Fetch Tenants from Physical Room via direct lookup (Fast) or Fallback Scan (Slow)
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('chatRooms')
                                    .doc(roomId)
                                    .get()
                                    .then((chatDoc) async {
                                      final chatData = chatDoc.data() as Map<String, dynamic>? ?? {};
                                      String? physicalRoomId = chatData['roomId'];
                                      String? linkedHouseId = chatData['houseId'];
                                      
                                      // Fallback: If roomId isn't stored, scan houses by room name (for legacy data)
                                      if (physicalRoomId == null) {
                                        final housesSnap = await FirebaseFirestore.instance
                                            .collection('houses')
                                            .where('userId', isEqualTo: ownerId)
                                            .get();
                                        
                                        for (var houseDoc in housesSnap.docs) {
                                          final roomsSnap = await houseDoc.reference
                                              .collection('rooms')
                                              .where('roomName', isEqualTo: chatRoomName)
                                              .limit(1)
                                              .get();
                                          if (roomsSnap.docs.isNotEmpty) {
                                            physicalRoomId = roomsSnap.docs.first.id;
                                            break; 
                                          }
                                        }
                                      }

                                      if (physicalRoomId == null) return [];

                                      // Query top-level tenants collection for this room
                                      final tenantsSnap = await FirebaseFirestore.instance
                                          .collection('tenants')
                                          .where('roomId', isEqualTo: physicalRoomId)
                                          .get();
                                          
                                      return tenantsSnap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                                    }),
                                builder: (context, membersSnap) {
                                  if (membersSnap.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                    );
                                  }
                                  
                                  final members = membersSnap.data ?? [];
                                  if (members.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                      child: Text('Chưa có thành viên nào khác', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                                    );
                                  }

                                  return Column(
                                    children: members.map((memberData) {
                                      final String displayName = memberData['name'] ?? 'Thành viên';
                                      String role = memberData['role'] ?? 'Thành viên';
                                      if (role == 'Tenant') role = 'Người thuê';
                                      return _buildMemberTile(displayName, role);
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 1, indent: 16),
                  _buildSettingsItem(
                    label: 'Hình nền',
                    trailing: const Text('Không có', style: TextStyle(color: Colors.black54)),
                    onTap: () {},
                  ),
                  if (isBotRoom && !isTenant) ...[
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

  Widget _buildMemberTile(String name, String role, {bool isOwner = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isOwner ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Icon(
              isOwner ? Icons.admin_panel_settings : Icons.person,
              size: 16,
              color: isOwner ? Colors.blue : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Chủ phòng',
                style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else if (role == 'Tenant' || role == 'Người thuê')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Người thuê',
                style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
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
