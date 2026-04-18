import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _chatRoomsRef => _firestore.collection('chatRooms');

  // Create new chat room
  Future<String> createNewChatRoom(String roomName, {String? userId, String? houseId, String? roomId}) async {
    try {
      DocumentReference docRef = await _chatRoomsRef.add({
        'roomName': roomName,
        'memberCount': 1, // Default starting value
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId ?? 'system',
        'houseId': houseId,
        'roomId': roomId,
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
      // First delete all messages
      await deleteAllMessages(chatRoomId);
      // Then delete the chatRoom document itself
      await _chatRoomsRef.doc(chatRoomId).delete();
    } catch (e) {
      print('Error deleting chat room: $e');
      rethrow;
    }
  }
}
