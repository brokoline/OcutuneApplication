import 'package:flutter/material.dart';
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

        return MessageBubble(
          message: msg['message'],
          isMe: isMe,
        );
      },
    );
  }
}
