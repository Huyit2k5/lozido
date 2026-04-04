import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chat_room.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_input_field.dart';
import 'chat_settings_page.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId; // The current user's ID
  final String userName; // The current user's name

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatService _chatService = ChatService();

  void _sendMessage(String text, bool isSticker) {
    if (text.isEmpty) return;

    final message = ChatMessage(
      senderId: widget.userId,
      senderName: widget.userName,
      text: text,
      timestamp: Timestamp.now(),
      isSticker: isSticker,
    );

    _chatService.sendMessage(widget.roomId, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orange,
              child: Icon(Icons.home, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roomName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    '2 thành viên',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.green),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSettingsPage(
                    roomName: widget.roomName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn nào.'));
                }
                return ListView.builder(
                  reverse: true, // Messages appear from bottom up
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      message: message,
                      isMe: message.senderId == widget.userId,
                    );
                  },
                );
              },
            ),
          ),
          ChatInputField(
            onSendMessage: (text, isSticker) => _sendMessage(text, isSticker),
            onPickImage: () {},
            onPickSticker: () {},
          ),
        ],
      ),
    );
  }
}
