import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import '../../../services/chat_service.dart';
import '../../../services/notification_service.dart';
import '../../pages/chat/chat_room_page.dart';

// ==========================================================
// MODELS (Chuẩn bị cho Firestore Realtime Message/Notification)
// Đây là các model dự kiến sẽ parse từ DocumentSnapshot của Firebase
// ==========================================================

class ChatMessageModel {
  final String id;
  final String senderName;
  final String senderRole;
  final int roleColorHex;
  final String avatarType; // bot, cskh, house, group
  final String messagePreview;
  final DateTime timestamp;
  final bool isPinned;
  final bool isRead;
  final String? extraBadgeText; // VD: "198 Phan Văn Trị"

  ChatMessageModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.roleColorHex,
    required this.avatarType,
    required this.messagePreview,
    required this.timestamp,
    required this.isPinned,
    required this.isRead,
    this.extraBadgeText,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String timeAgo;
  final bool isUnread;
  final String type; // invoice | chat | system

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.timeAgo,
    required this.isUnread,
    this.type = 'system',
  });
}

// ==========================================================
// MAIN MAIL PAGE VIEW
// ==========================================================

class MailPage extends StatefulWidget {
  final String? tenantRoomName;
  final String? landlordId;
  final String? tenantUid;
  final String? tenantName;

  const MailPage({
    Key? key,
    this.tenantRoomName,
    this.landlordId,
    this.tenantUid,
    this.tenantName,
  }) : super(key: key);

  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  // 0: Tin nhắn, 1: Thông báo
  int _selectedTabIndex = 0;

  final NotificationService _notificationService = NotificationService();

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return widget.tenantUid ?? user?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
  }


  void _showCreateChatRoomDialog(BuildContext context, String currentUserId) async {
    final housesSnapshot = await FirebaseFirestore.instance
        .collection('houses')
        .where('userId', isEqualTo: currentUserId)
        .get();

    if (housesSnapshot.docs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa quản lý nhà trọ nào!')),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn nhà trọ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: housesSnapshot.docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = housesSnapshot.docs[index];
                final data = doc.data();
                final displayTitle = (data['houseName'] ?? data['propertyName'] ?? "Nhà trọ của tôi").toString();
                final String roomName = displayTitle.isEmpty ? "Nhà trọ của tôi" : displayTitle;

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.home, color: Colors.white, size: 20),
                  ),
                  title: Text(roomName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context); // Đóng dialog
                    final chatService = ChatService();
                    await chatService.createNewChatRoom(roomName, userId: currentUserId);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã tạo nhóm chat cho $roomName!'), backgroundColor: Colors.deepOrange),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - bọc StreamBuilder để hiển thị số thông báo chưa đọc realtime
            StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getNotifications(_currentUserId),
              builder: (context, notiSnap) {
                final int unreadCount = (notiSnap.data ?? [])
                    .where((n) => n.isUnread)
                    .length;
                return CustomHeader(
                  selectedIndex: _selectedTabIndex,
                  unreadNotiCount: unreadCount,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  onAddPressed: () async {
                    final ChatService chatService = ChatService();
                    final user = FirebaseAuth.instance.currentUser;
                    final String currentUserId = user?.uid ?? "anonymous";
                    final String currentUserName = user?.displayName ?? "Người dùng";

                    // Tạo phòng chat mới với tên mặc định hoặc yêu cầu nhập
                    String roomId = await chatService.createNewChatRoom("Nhà trọ 198 Phan Văn Trị");
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomPage(
                            roomId: roomId,
                            roomName: "Nhà trọ 198 Phan Văn Trị",
                            userId: currentUserId,
                            userName: currentUserName,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            
            // Phần hiển thị nội dung dùng Expanded (Bọc StreamBuilder cho realtime firebase data)
            Expanded(
              child: _selectedTabIndex == 0 
                  ? _buildMessagesTab() 
                  : _buildNotificationsTab(),
            )
          ],
        ),
      ),
    );
  }

  // Giao diện khi chọn tab Tin Nhắn (áp dụng StreamBuilder chuẩn bị cho Firestore)
  Widget _buildMessagesTab() {
    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = widget.tenantUid ?? user?.uid ?? "anonymous";
    final String currentUserName = widget.tenantName ?? user?.displayName ?? "Người dùng";
    final bool isTenant = widget.landlordId != null;

    return ListView(
      children: [
        // 1. Pinned Chatbot CSKH (Luôn ở trên cùng)
        _buildChatRoomTile(
          roomId: 'bot_$currentUserId', 
          roomName: 'Lozido CSKH', 
          isBot: true,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          isPinned: true,
        ),
        const Divider(height: 1, indent: 80, color: Color(0xFFEEEEEE)),

        // 2. Danh sách Phòng chat từ Firestore 'chatRooms'
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chatRooms')
              .where('userId', isEqualTo: widget.landlordId ?? user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink(); // Silent loading for dynamic rooms
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            var docs = snapshot.data!.docs;
            
            // Nếu là người thuê, chỉ hiện phòng của họ
            if (isTenant && widget.tenantRoomName != null) {
              docs = docs.where((doc) {
                final name = (doc.data() as Map<String, dynamic>)['roomName'] ?? '';
                return name.toString().toLowerCase() == widget.tenantRoomName!.toLowerCase();
              }).toList();
            } else {
              // Nếu là chủ nhà, lọc bỏ CSKH (vì đã có pinned) và sắp xếp
              docs = docs.where((doc) {
                final name = (doc.data() as Map<String, dynamic>)['roomName'] ?? '';
                return name.toString().toLowerCase() != 'lozido cskh';
              }).toList();
              
              docs.sort((a, b) {
                // Sắp xếp theo tên hoặc thời gian (tùy ý)
                return 0; 
              });
            }

            if (docs.isEmpty && !isTenant) {
               return _buildEmptyState(currentUserId);
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String roomName = data['roomName'] ?? 'Không tên';
                final String roomId = doc.id;
                final bool isBot = roomName.toLowerCase() == 'lozido cskh';
                final int unreadCount = (data['unreadCounts']?[currentUserId] as num?)?.toInt() ?? 0;
                final String lastMessage = data['lastMessage'] as String? ?? "Nhấn để xem chi tiết";

                return _buildChatRoomTile(
                  roomId: roomId,
                  roomName: roomName,
                  isBot: isBot,
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  unreadCount: unreadCount,
                  lastMessage: lastMessage,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(String currentUserId) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.house_siding, size: 48, color: Colors.orange.shade300),
          const SizedBox(height: 12),
          const Text(
            "Chưa có nhóm chat, vui lòng tạo nhóm chat cho nhà trọ",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateChatRoomDialog(context, currentUserId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text("Tạo nhóm chat", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile({
    required String roomId,
    required String roomName,
    required bool isBot,
    required String currentUserId,
    required String currentUserName,
    bool isPinned = false,
    int unreadCount = 0,
    String lastMessage = "Nhấn để xem chi tiết",
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: (isBot ? Colors.blue : const Color(0xFFFF5722)).withOpacity(0.1),
            child: Icon(isBot ? Icons.smart_toy : Icons.home, color: isBot ? Colors.blue : const Color(0xFFFF5722), size: 28),
          ),
          title: Text(
            roomName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.deepOrange.withOpacity(0.1) : const Color(0xFFFF5722),
                      border: isBot ? Border.all(color: Colors.deepOrange) : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isBot ? "Chatbot CSKH" : "Nhà trọ",
                      style: TextStyle(
                        color: isBot ? Colors.deepOrange : Colors.white, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastMessage, 
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chatRooms')
                .doc(roomId)
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final bool notifyLandlord = data['notifyLandlord'] == true || data['notifyLandlord'] == null;
              final bool notifyTenant = data['notifyTenant'] == true || data['notifyTenant'] == null;
              final bool isTenant = widget.landlordId != null;
              final bool isMuted = isTenant ? !notifyTenant : !notifyLandlord;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMuted)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          onTap: () async {
            String finalRoomId = roomId;
            
            // Nếu là bot room pinned, ta cần check/tạo room thật trong Firestore
            if (isBot && isPinned) {
              final chatService = ChatService();
              // Tìm room 'Lozido CSKH' của user này
              String? existingRoomId = await chatService.findChatRoomByName('Lozido CSKH', currentUserId);
              if (existingRoomId == null) {
                finalRoomId = await chatService.createNewChatRoom('Lozido CSKH', userId: currentUserId);
              } else {
                finalRoomId = existingRoomId;
              }
            }

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                  roomId: finalRoomId,
                  roomName: roomName,
                  userId: currentUserId,
                  userName: currentUserName,
                  isTenant: widget.landlordId != null,
                ),
              ),
            );
          },
        ),
        if (!isPinned) const Divider(height: 1, indent: 80, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // Giao diện khi chọn tab Thông báo - Realtime từ Firestore
  Widget _buildNotificationsTab() {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      return const Center(child: Text('Không thể tải thông báo.'));
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Chưa có thông báo nào.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return NotificationItemWidget(
              model: items[index],
              onTap: () {
                if (items[index].isUnread) {
                  _notificationService.markAsRead(items[index].id);
                }
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================================
// THÀNH PHẦN U.I (WIDGETS) ĐƯỢC CHIA NHỎ THEO YÊU CẦU
// ==========================================================

// Header Tuỳ Chỉnh chứa Button chuyển đổi Tab và các Icon điều hướng
class CustomHeader extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final VoidCallback onAddPressed;
  final int unreadNotiCount;

  const CustomHeader({
    Key? key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onAddPressed,
    this.unreadNotiCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút CộNG (+)
          Opacity(
            opacity: 0.5,
            child: GestureDetector(
              onTap: null, // Vô hiệu hóa hành động
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.add, color: Color(0xFF26A69A), size: 20),
              ),
            ),
          ),

          // Hai Tab (Tin nhắn / Thông báo) với animation nằm ngay trung tâm
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Row(
              children: [
                BounceTabItem(
                  title: 'Tin nhắn',
                  subtitle: '0 - chưa đọc',
                  iconPath: Icons.chat_bubble_outline,
                  isSelected: selectedIndex == 0,
                  onTap: () => onTabChanged(0),
                ),
                const SizedBox(width: 4),
                BounceTabItem(
                  title: 'Thông báo',
                  subtitle: unreadNotiCount > 0
                      ? '$unreadNotiCount - chưa đọc'
                      : 'Không có mới',
                  iconPath: Icons.notifications_none,
                  isSelected: selectedIndex == 1,
                  showSmallBell: unreadNotiCount > 0,
                  onTap: () => onTabChanged(1),
                ),
              ],
            ),
          ),

          // Nút Cài Đặt
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.black87, size: 20),
          ),
        ],
      ),
    );
  }
}

// WIDGET TAB ITEM VỚI HIỆU ỨNG ANIMATION RẤT MƯỢT MÀ VÀ NỔI BẬT
class BounceTabItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData iconPath;
  final bool isSelected;
  final bool showSmallBell;
  final VoidCallback onTap;

  const BounceTabItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
    this.showSmallBell = false,
  }) : super(key: key);

  @override
  State<BounceTabItem> createState() => _BounceTabItemState();
}

class _BounceTabItemState extends State<BounceTabItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animation controller xử lý hiệu ứng nảy (spring bounce) trong 300ms
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300)
    );
    
    // Tạo Tween cho hiệu ứng scale icon bật ra (1.0 -> 1.3 -> 1.0) để gây chú ý
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutCubic)), 
        weight: 40
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), 
        weight: 60
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isSelected) {
      widget.onTap();
      // Kích hoạt hiệu ứng nảy cho icon ngay sau khi tap
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màu xanh nhạt (Light Teal / Xanh ngọc) cho phần selected
    final Color selectedBg = const Color(0xFFE8F5E9); 
    final Color selectedBorder = const Color(0xFF81C784); 
    final Color selectedIconColor = const Color(0xFF26A69A);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected ? selectedBg : Colors.transparent, 
          border: Border.all(
            color: widget.isSelected ? selectedBorder : Colors.transparent, 
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Icon với hiệu ứng Scale nảy lên mượt mà (chỉ icon nảy)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                   Icon(
                      widget.iconPath, 
                      color: widget.isSelected ? selectedIconColor : Colors.grey.shade600,
                      size: 20,
                   ),
                   // Hiển thị vòng bé nếu là chuông chưa đọc
                   if (widget.showSmallBell)
                     Positioned(
                       top: 0,
                       right: 0,
                       child: Container(
                         width: 6,
                         height: 6,
                         decoration: const BoxDecoration(
                           color: Colors.redAccent,
                           shape: BoxShape.circle,
                         ),
                       ),
                     ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                    color: widget.isSelected ? selectedIconColor : Colors.black87,
                    fontSize: 13,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: widget.isSelected ? selectedIconColor.withOpacity(0.8) : Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// MessageItemWidget đã được thay thế bằng ListTile trực tiếp trong _buildMessagesTab để đồng bộ giao diện.

// Custom ListItem Layout cho Thông Báo với dạng Card nhẹ
class NotificationItemWidget extends StatelessWidget {
  final NotificationModel model;
  final VoidCallback? onTap;

  const NotificationItemWidget({Key? key, required this.model, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isInvoice = model.type == 'invoice';
    final bool isChat = model.type == 'chat';

    final Color iconColor = isInvoice
        ? const Color(0xFFFF8C00)
        : isChat
            ? const Color(0xFF26A69A)
            : const Color(0xFF81C784);

    final IconData iconData = isInvoice
        ? Icons.receipt_long
        : isChat
            ? Icons.chat_bubble
            : Icons.notifications;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: model.isUnread ? iconColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: model.isUnread ? iconColor.withOpacity(0.25) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(iconData, color: iconColor, size: 24),
                  if (model.isUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.title,
                    style: TextStyle(
                      fontWeight: model.isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.content,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    model.timeAgo,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (model.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// Fake Bottom Navigation Bar (Được yêu cầu tách ra)
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavBar({Key? key, this.currentIndex = 1, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, "Trang chủ", currentIndex == 0),
          _buildNavItem(1, Icons.chat_bubble_outline, "Hộp thư", currentIndex == 1),
          _buildNavItem(2, Icons.grid_view, "Thêm +", currentIndex == 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap!(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom background shape if selected
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent, // Nền xanh nhạt nếu chọn
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
               icon, 
               color: isSelected ? const Color(0xFF26A69A) : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF26A69A) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
            ),
          )
        ],
      ),
    );
  }
}
