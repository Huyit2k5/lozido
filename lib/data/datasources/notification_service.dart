import 'package:cloud_firestore/cloud_firestore.dart';
import '../../presentation/pages/home/mail_page.dart' show NotificationModel;

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  CollectionReference get _chatRoomsRef => _firestore.collection('chatRooms');

  // ────────────────────────────────────────────────
  // Gửi thông báo đến một user cụ thể
  // ────────────────────────────────────────────────
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String content,
    String type = 'system',
  }) async {
    if (targetUserId.isEmpty) return;
    try {
      await _notificationsRef.add({
        'userId': targetUserId,
        'title': title,
        'content': content,
        'type': type,
        'isUnread': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[NotificationService] sendNotification error: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Gửi thông báo đến người thuê đứng tên phòng
  // (query collection 'tenants' theo houseId + roomId)
  // ────────────────────────────────────────────────
  Future<void> sendNotificationToTenant({
    required String houseId,
    required String roomId,
    required String title,
    required String content,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .where('houseId', isEqualTo: houseId)
          .where('roomId', isEqualTo: roomId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final tenantData = snapshot.docs.first.data();
      final String? tenantUid = tenantData['uid'] as String?;
      if (tenantUid == null || tenantUid.isEmpty) return;

      await sendNotification(
        targetUserId: tenantUid,
        title: title,
        content: content,
        type: 'invoice',
      );
    } catch (e) {
      print('[NotificationService] sendNotificationToTenant error: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Lấy luồng thông báo realtime của một user
  // (Không dùng orderBy để tránh cần composite index)
  // Sắp xếp theo createdAt phía client
  // ────────────────────────────────────────────────
  Stream<List<NotificationModel>> getNotifications(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? ts = data['createdAt'] as Timestamp?;
        final DateTime date = ts?.toDate() ?? DateTime.now();
        return NotificationModel(
          id: doc.id,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          date: date,
          timeAgo: _timeAgo(date),
          isUnread: data['isUnread'] as bool? ?? false,
          type: data['type'] as String? ?? 'system',
        );
      }).toList();

      // Sắp xếp mới nhất lên đầu phía client
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ────────────────────────────────────────────────
  // Đánh dấu một thông báo đã đọc
  // ────────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isUnread': false});
    } catch (e) {
      print('[NotificationService] markAsRead error: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Đánh dấu tất cả thông báo của user đã đọc
  // ────────────────────────────────────────────────
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isUnread', isEqualTo: true)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isUnread': false});
      }
      await batch.commit();
    } catch (e) {
      print('[NotificationService] markAllAsRead error: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Quản lý activeUsers trong chatRoom
  // Gọi joinRoom khi người dùng mở ChatRoomPage
  // ────────────────────────────────────────────────
  Future<void> joinRoom(String roomId, String userId) async {
    try {
      await _chatRoomsRef.doc(roomId).update({
        'activeUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('[NotificationService] joinRoom error: $e');
    }
  }

  // Gọi leaveRoom khi người dùng thoát ChatRoomPage
  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await _chatRoomsRef.doc(roomId).update({
        'activeUsers': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('[NotificationService] leaveRoom error: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Helper: Chuyển DateTime thành chuỗi "... trước"
  // ────────────────────────────────────────────────
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}
