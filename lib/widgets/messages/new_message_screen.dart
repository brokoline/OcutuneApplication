import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/new_message_form.dart';

class NewMessageScreen extends StatelessWidget {
  const NewMessageScreen({super.key});

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
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: const NewMessageForm(),
    );
  }
}
