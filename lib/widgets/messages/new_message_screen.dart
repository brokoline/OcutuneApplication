import 'package:flutter/material.dart';
import '../../services/services/message_service.dart';
import '../../theme/colors.dart';
import 'new_message_form.dart';

class NewMessageScreen extends StatelessWidget {
  final UserRole senderRole;

  const NewMessageScreen({super.key, required this.senderRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Ny besked',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: NewMessageForm(senderRole: senderRole),
    );
  }
}
