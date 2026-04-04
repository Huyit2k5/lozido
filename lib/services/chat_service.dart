import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _chatRoomsRef => _firestore.collection('chatRooms');

  // Create new chat room
  Future<String> createNewChatRoom(String roomName, {String? userId}) async {
    try {
      DocumentReference docRef = await _chatRoomsRef.add({
        'roomName': roomName,
        'memberCount': 1, // Default starting value
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId ?? 'system',
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

  // Send a message
  Future<void> sendMessage(String roomId, ChatMessage message) async {
    try {
      await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .add(message.toFirestore());
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
}
