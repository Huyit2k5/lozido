import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/chat_viewmodel.dart';

class ChatSettingsPage extends StatefulWidget {
  final String roomName;
  final String roomId;
  final bool isTenant;

  const ChatSettingsPage({
    super.key,
    required this.roomName,
    required this.roomId,
    this.isTenant = false,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  bool get isBotRoom => widget.roomName.toLowerCase() == 'lozido cskh' || widget.roomName.toLowerCase() == 'irental cskh';

  // Cập nhật trường thông báo trong Firestore
  Future<void> _toggleNotification(String field, bool currentValue) async {
    await context.read<ChatViewModel>().toggleNotification(widget.roomId, field, currentValue);
  }

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
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.roomName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBotRoom ? 'Hỗ trợ trực tuyến IRental' : 'Trao đổi trong ${widget.roomName}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings List — dùng StreamBuilder để đọc realtime từ Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: context.read<ChatViewModel>().getRawRoomDetails(widget.roomId),
              builder: (context, snapshot) {
                // Hiển thị skeleton khi đang tải
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                // Bỏ qua khi lỗi, hiển thị rỗng
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final chatRoomData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                // Safe cast — mặc định bật nếu chưa có trường
                final bool notifyLandlord =
                    chatRoomData['notifyLandlord'] == true ||
                        chatRoomData['notifyLandlord'] == null;
                final bool notifyTenant =
                    chatRoomData['notifyTenant'] == true ||
                        chatRoomData['notifyTenant'] == null;

                // Safe cast số nguyên từ Firestore
                final int tenantCount =
                    (chatRoomData['memberCount'] as num?)?.toInt() ?? 0;
                final String ownerId = chatRoomData['userId'] as String? ?? '';
                final String chatRoomName =
                    chatRoomData['roomName'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // ── Thông báo cho Chủ nhà ──
                      if (!widget.isTenant) ...[
                        _buildNotificationToggle(
                          label: 'Nhận thông báo (Chủ nhà)',
                          subtitle: 'Nhận thông báo khi có tin nhắn mới',
                          value: notifyLandlord,
                          onChanged: (_) =>
                              _toggleNotification('notifyLandlord', notifyLandlord),
                        ),
                        const Divider(height: 1, indent: 16),
                      ],

                      // ── Thông báo cho Người thuê ──
                      if (widget.isTenant) ...[
                        _buildNotificationToggle(
                          label: 'Nhận thông báo (Người thuê)',
                          subtitle: 'Nhận thông báo khi có tin nhắn mới',
                          value: notifyTenant,
                          onChanged: (_) =>
                              _toggleNotification('notifyTenant', notifyTenant),
                        ),
                        const Divider(height: 1, indent: 16),
                      ],

                      // ── Danh sách thành viên ──
                      if (!isBotRoom)
                        Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text('Thành viên nhóm',
                                style: TextStyle(fontSize: 15)),
                            trailing: Text(
                              'Xem ${tenantCount + 1} thành viên',
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                            childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            children: [
                              // 1. Chủ phòng
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(ownerId)
                                    .get(),
                                builder: (context, ownerSnap) {
                                  String ownerName = 'Đang tải...';
                                  if (ownerSnap.hasData &&
                                      ownerSnap.data!.exists) {
                                    final data = ownerSnap.data!.data()
                                        as Map<String, dynamic>;
                                    ownerName = data['name'] ?? 'Chủ phòng';
                                  }
                                  return _buildMemberTile(ownerName, 'Chủ phòng',
                                      isOwner: true);
                                },
                              ),
                              // 2. Người thuê
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('chatRooms')
                                    .doc(widget.roomId)
                                    .get()
                                    .then((chatDoc) async {
                                  final cData = chatDoc.data() ?? {};
                                  String? physicalRoomId = cData['roomId'];

                                  if (physicalRoomId == null) {
                                    final housesSnap = await FirebaseFirestore
                                        .instance
                                        .collection('houses')
                                        .where('userId', isEqualTo: ownerId)
                                        .get();
                                    for (var houseDoc in housesSnap.docs) {
                                      final roomsSnap = await houseDoc.reference
                                          .collection('rooms')
                                          .where('roomName',
                                              isEqualTo: chatRoomName)
                                          .limit(1)
                                          .get();
                                      if (roomsSnap.docs.isNotEmpty) {
                                        physicalRoomId =
                                            roomsSnap.docs.first.id;
                                        break;
                                      }
                                    }
                                  }
                                  if (physicalRoomId == null) return [];
                                  final tenantsSnap = await FirebaseFirestore
                                      .instance
                                      .collection('tenants')
                                      .where('roomId',
                                          isEqualTo: physicalRoomId)
                                      .get();
                                  return tenantsSnap.docs
                                      .map((doc) =>
                                          doc.data())
                                      .toList();
                                }),
                                builder: (context, membersSnap) {
                                  if (membersSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))),
                                    );
                                  }
                                  final members = membersSnap.data ?? [];
                                  if (members.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 4.0),
                                      child: Text(
                                          'Chưa có thành viên nào khác',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic)),
                                    );
                                  }
                                  return Column(
                                    children: members.map((memberData) {
                                      final String displayName =
                                          memberData['name'] ?? 'Thành viên';
                                      String role =
                                          memberData['role'] ?? 'Thành viên';
                                      if (role == 'Tenant') role = 'Người thuê';
                                      return _buildMemberTile(
                                          displayName, role);
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      const Divider(height: 1, indent: 16),

                      // ── Upload PDF cho Chatbot (chỉ chủ nhà) ──
                      if (isBotRoom && !widget.isTenant)
                        _buildSettingsItem(
                          label: 'Thêm tài liệu cho Chatbot (PDF)',
                          trailing: const Icon(Icons.picture_as_pdf,
                              color: Colors.redAccent),
                          onTap: () => _uploadPdf(context),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Widget toggle thông báo ──
  Widget _buildNotificationToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: value ? Colors.green : Colors.grey,
        ),
      ),
      value: value,
      activeThumbColor: Colors.green,
      secondary: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          value ? Icons.notifications_active : Icons.notifications_off,
          color: value ? Colors.green : Colors.grey,
          size: 22,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSettingsItem(
      {required String label,
      required Widget trailing,
      VoidCallback? onTap}) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
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
            backgroundColor: isOwner
                ? Colors.blue.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
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
                    fontWeight:
                        isOwner ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(role,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              child: const Text('Chủ phòng',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          else if (role == 'Tenant' || role == 'Người thuê')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Người thuê',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
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

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final storageRef = FirebaseStorage.instance.ref();
        final pdfsRef = storageRef.child(
            'pdfs/bot_${DateTime.now().millisecondsSinceEpoch}_$fileName');

        if (kIsWeb) {
          await pdfsRef.putData(platformFile.bytes!);
        } else {
          if (platformFile.bytes != null) {
            await pdfsRef.putData(platformFile.bytes!);
          } else if (platformFile.path != null) {
            await pdfsRef.putData(await platformFile.xFile.readAsBytes());
          }
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải tài liệu PDF thành công!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải file: $e')),
        );
      }
    }
  }
}
