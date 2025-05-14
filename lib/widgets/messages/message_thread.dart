import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/widgets/messages/message_bubble.dart';

class MessageThread extends StatelessWidget {
  final List<Map<String, dynamic>> messages;

  const MessageThread({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg['sender_type'] == 'patient';
        final time = _formatDateTime(msg['sent_at']);

        return Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MessageBubble(
              message: msg['message'],
              isMe: isMe,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _formatDateTime(String rawDate) {
    try {
      final dt = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .parseUtc(rawDate)
          .toLocal();
      return DateFormat('dd.MM.yyyy • HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }
}
