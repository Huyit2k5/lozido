import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String roomId;
  final String roomName;
  final int memberCount;

  ChatRoom({
    required this.roomId,
    required this.roomName,
    required this.memberCount,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      roomId: doc.id,
      roomName: data['roomName'] ?? '',
      memberCount: data['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomName': roomName,
      'memberCount': memberCount,
    };
  }
}
