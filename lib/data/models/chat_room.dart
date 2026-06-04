import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String roomId;
  final String roomName;
  final int memberCount;
  final String? lastMessage;
  final Timestamp? lastMessageTime;
  final Map<String, int> unreadCounts;

  ChatRoom({
    required this.roomId,
    required this.roomName,
    required this.memberCount,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCounts = const {},
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    // Convert unreadCounts to Map<String, int>
    Map<String, int> parsedUnreadCounts = {};
    if (data['unreadCounts'] != null) {
      (data['unreadCounts'] as Map<String, dynamic>).forEach((key, value) {
        parsedUnreadCounts[key] = (value as num).toInt();
      });
    }

    return ChatRoom(
      roomId: doc.id,
      roomName: data['roomName'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'],
      unreadCounts: parsedUnreadCounts,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomName': roomName,
      'memberCount': memberCount,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCounts': unreadCounts,
    };
  }
}
