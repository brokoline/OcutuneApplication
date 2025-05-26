import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ReplyInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) {
              print('📲 ENTER trykket – sender besked');
              if (controller.text.trim().isNotEmpty) {
                onSend();
              }
            },
            style: const TextStyle(color: Colors.white70),
            decoration: InputDecoration(
              hintText: 'Skriv en besked...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: darkGray,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.white70),
          onPressed: () {
            final text = controller.text.trim();
            print('📤 Send-knap trykket: "$text"');
            if (text.isNotEmpty) {
              onSend();
            }
          },
        ),
      ],
    );
  }
}
