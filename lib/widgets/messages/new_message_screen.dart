import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'new_message_form.dart';

class NewMessageScreen extends StatelessWidget {
  const NewMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ny besked',
          style: TextStyle(color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: const SafeArea(
        child: NewMessageForm(),
      ),
    );
  }
}
