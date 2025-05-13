import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class NewMessageForm extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final bool sending;
  final String sendButtonLabel;

  const NewMessageForm({
    super.key,
    required this.subjectController,
    required this.messageController,
    required this.onSend,
    this.sending = false,
    this.sendButtonLabel = 'Send besked',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: subjectController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Emne',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TextField(
            controller: messageController,
            style: const TextStyle(color: Colors.white),
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Skriv din besked...',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: sending ? null : onSend,
          icon: sending
              ? const CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          )
              : const Icon(Icons.send),
          label: Text(sending ? 'Sender...' : sendButtonLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
