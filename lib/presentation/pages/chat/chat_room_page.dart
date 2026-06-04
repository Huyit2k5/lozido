import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../viewmodels/chat_viewmodel.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_input_field.dart';
import 'chat_settings_page.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId; // The current user's ID
  final String userName; // The current user's name
  final bool isTenant;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.userName,
    this.isTenant = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatViewModel = context.read<ChatViewModel>();
      chatViewModel.markRoomAsRead(widget.roomId, widget.userId);
      chatViewModel.joinRoom(widget.roomId, widget.userId);
    });
  }

  @override
  void dispose() {
    // We cannot use context.read in dispose easily, but we can store it or use Provider.of(context, listen: false) if we override didChangeDependencies, 
    // or just call it directly if we cache the viewmodel. 
    // To be safe, we'll cache it in initState.
    super.dispose();
  }

  ChatViewModel? _chatViewModel;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatViewModel ??= context.read<ChatViewModel>();
  }

  @override
  void deactivate() {
    _chatViewModel?.leaveRoom(widget.roomId, widget.userId);
    super.deactivate();
  }

  void _sendMessage(String text, bool isSticker) {
    if (text.isEmpty) return;

    context.read<ChatViewModel>().sendMessage(widget.roomId, widget.userId, widget.userName, text, isSticker);
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
            CircleAvatar(
              radius: 18,
              backgroundColor: (widget.roomName.toLowerCase() == 'lozido cskh' || widget.roomName.toLowerCase() == 'irental cskh') ? Colors.blue : Colors.orange,
              child: Icon(
                (widget.roomName.toLowerCase() == 'lozido cskh' || widget.roomName.toLowerCase() == 'irental cskh') ? Icons.smart_toy : Icons.home, 
                color: Colors.white, 
                size: 20
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (widget.roomName.toLowerCase() == 'lozido cskh' || widget.roomName.toLowerCase() == 'irental cskh') ? 'IRental CSKH' : widget.roomName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: context.read<ChatViewModel>().getRawRoomDetails(widget.roomId),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                      final count = (data['memberCount'] as num?)?.toInt() ?? 0;
                      if (widget.roomName.toLowerCase() == 'lozido cskh' || widget.roomName.toLowerCase() == 'irental cskh') {
                        return const Text(
                          'Hỗ trợ trực tuyến',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return Text(
                        '${count + 1} thành viên',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Biểu tượng chuông gạch khi tắt thông báo phòng này
          StreamBuilder<DocumentSnapshot>(
            stream: context.read<ChatViewModel>().getRawRoomDetails(widget.roomId),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final bool notifyLandlord = data['notifyLandlord'] as bool? ?? true;
              final bool notifyTenant = data['notifyTenant'] as bool? ?? true;
              final bool isMuted =
                  widget.isTenant ? !notifyTenant : !notifyLandlord;
              if (!isMuted) return const SizedBox.shrink();
              return Tooltip(
                message: 'Thông báo đã tắt',
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSettingsPage(
                    roomName: widget.roomName,
                    roomId: widget.roomId,
                    isTenant: widget.isTenant,
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
              stream: context.read<ChatViewModel>().getMessages(widget.roomId),
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
                      isBotRoom: widget.roomName.toLowerCase() == 'lozido cskh' || widget.roomName.toLowerCase() == 'irental cskh',
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
