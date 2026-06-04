import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/chat_repository.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_room.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;

  ChatViewModel({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? ChatRepository();

  Stream<QuerySnapshot> getChatRoomsStream(String userId) {
    return _chatRepository.getChatRoomsStream(userId);
  }

  void markRoomAsRead(String roomId, String userId) {
    _chatRepository.markRoomAsRead(roomId, userId);
  }

  void joinRoom(String roomId, String userId) {
    _chatRepository.joinRoom(roomId, userId);
  }

  void leaveRoom(String roomId, String userId) {
    _chatRepository.leaveRoom(roomId, userId);
  }

  void sendMessage(String roomId, String userId, String userName, String text, bool isSticker) {
    if (text.isEmpty) return;
    final message = ChatMessage(
      senderId: userId,
      senderName: userName,
      text: text,
      timestamp: Timestamp.now(),
      isSticker: isSticker,
    );
    _chatRepository.sendMessage(roomId, message);
  }

  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _chatRepository.getMessages(roomId);
  }

  Stream<ChatRoom> getRoomDetails(String roomId) {
    return _chatRepository.getRoomDetails(roomId);
  }

  Stream<DocumentSnapshot> getRawRoomDetails(String roomId) {
    return _chatRepository.getRawRoomDetails(roomId);
  }

  Future<void> toggleNotification(String roomId, String field, bool currentValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(roomId)
          .update({field: !currentValue});
    } catch (e) {
      debugPrint('[ChatViewModel] toggleNotification error: $e');
    }
  }
}
