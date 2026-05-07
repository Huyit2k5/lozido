import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection reference
  CollectionReference get _chatRoomsRef => _firestore.collection('chatRooms');

  // Create new chat room
  Future<String> createNewChatRoom(String roomName, {String? userId, String? houseId, String? roomId}) async {
    try {
      DocumentReference docRef = await _chatRoomsRef.add({
        'roomName': roomName,
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId ?? 'system',
        'houseId': houseId,
        'roomId': roomId,
        'unreadCounts': userId != null ? {userId: 0} : {},
        'activeUsers': [],
      });
      return docRef.id;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // Get messages stream for a specific room
  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _chatRoomsRef
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  // Send a message — also sends notification to members who are NOT in the room
  Future<void> sendMessage(String roomId, ChatMessage message) async {
    try {
      await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .add(message.toFirestore());

      // Lấy dữ liệu phòng chat
      DocumentSnapshot roomDoc = await _chatRoomsRef.doc(roomId).get();
      Map<String, dynamic> data = roomDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> unreadCounts = data['unreadCounts'] ?? {};
      List<dynamic> activeUsers = data['activeUsers'] ?? [];
      final String roomName = data['roomName'] ?? 'Nhà trọ';
      final String ownerId = data['userId'] ?? '';

      // Cài đặt thông báo — mặc định bật nếu chưa có trường
      final bool notifyLandlord = data['notifyLandlord'] as bool? ?? true;
      final bool notifyTenant = data['notifyTenant'] as bool? ?? true;

      Map<String, dynamic> updates = {
        'lastMessage': message.isSticker ? '[Sticker]' : message.text,
        'lastMessageTime': message.timestamp,
      };

      final String notifContent = message.isSticker
          ? '${message.senderName} đã gửi một nhãn dán.'
          : '${message.senderName}: ${message.text}';
      const String notifTitle = '💬 Tin nhắn mới';

      // Tăng unreadCount và gửi thông báo cho các thành viên không phải người gửi
      for (String key in unreadCounts.keys) {
        if (key != message.senderId) {
          updates['unreadCounts.$key'] = FieldValue.increment(1);

          // Chỉ gửi thông báo nếu người nhận KHÔNG đang mở phòng chat
          if (!activeUsers.contains(key)) {
            // Xác định người nhận là chủ nhà hay người thuê để check cài đặt
            final bool isLandlord = key == ownerId;
            final bool shouldNotify =
                isLandlord ? notifyLandlord : notifyTenant;

            if (shouldNotify) {
              await _notificationService.sendNotification(
                targetUserId: key,
                title: notifTitle,
                content: notifContent,
                type: 'chat',
              );
            }
          }
        }
      }

      // Nếu chủ phòng chưa có trong map, thêm vào
      if (ownerId.isNotEmpty && ownerId != message.senderId && !unreadCounts.containsKey(ownerId)) {
        updates['unreadCounts.$ownerId'] = 1;
        if (!activeUsers.contains(ownerId) && notifyLandlord) {
          await _notificationService.sendNotification(
            targetUserId: ownerId,
            title: notifTitle,
            content: notifContent,
            type: 'chat',
          );
        }
      }

      // Đảm bảo người gửi có trong map
      if (!unreadCounts.containsKey(message.senderId)) {
        updates['unreadCounts.${message.senderId}'] = 0;
      }

      await _chatRoomsRef.doc(roomId).update(updates);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get room details
  Stream<ChatRoom> getRoomDetails(String roomId) {
    return _chatRoomsRef.doc(roomId).snapshots().map((doc) {
      return ChatRoom.fromFirestore(doc);
    });
  }

  // Find chatRoom by roomName and userId
  Future<String?> findChatRoomByName(String roomName, String userId) async {
    try {
      final query = await _chatRoomsRef
          .where('roomName', isEqualTo: roomName)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error finding chat room: $e');
      return null;
    }
  }

  // Delete all messages in a chatRoom (keep the chatRoom document)
  Future<void> deleteAllMessages(String chatRoomId) async {
    try {
      final messagesRef = _chatRoomsRef.doc(chatRoomId).collection('messages');
      final snapshots = await messagesRef.get();
      final batch = _firestore.batch();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting messages: $e');
      rethrow;
    }
  }

  // Delete entire chatRoom document (and its messages sub-collection)
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      await deleteAllMessages(chatRoomId);
      await _chatRoomsRef.doc(chatRoomId).delete();
    } catch (e) {
      print('Error deleting chat room: $e');
      rethrow;
    }
  }

  // Đánh dấu phòng chat đã đọc
  Future<void> markRoomAsRead(String roomId, String userId) async {
    try {
      await _chatRoomsRef.doc(roomId).update({
        'unreadCounts.$userId': 0
      });
    } catch (e) {
      print('Error marking room as read: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Quản lý activeUsers — delegate sang NotificationService
  // ────────────────────────────────────────────────

  Future<void> joinRoom(String roomId, String userId) =>
      _notificationService.joinRoom(roomId, userId);

  Future<void> leaveRoom(String roomId, String userId) =>
      _notificationService.leaveRoom(roomId, userId);
}

