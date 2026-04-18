import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isBotRoom;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isBotRoom = false,
  });

  Widget _buildMessageText(String text) {
    if (!text.contains('**')) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
      );
    }

    final List<TextSpan> spans = [];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      
      final isBold = i % 2 != 0; // Odd indices are inside **
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: isBotRoom ? Colors.blue : Colors.orange,
              child: Icon(
                isBotRoom ? Icons.smart_toy : Icons.person, 
                color: Colors.white
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        color: isBotRoom ? Colors.blue : const Color(0xFF8B0000),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFE0F8D8) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isSticker)
                        Image.network(
                          message.text,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        )
                      else
                        _buildMessageText(message.text),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm:ss')
                                .format(message.timestamp.toDate()),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isMe ? Icons.done_all : Icons.done,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
