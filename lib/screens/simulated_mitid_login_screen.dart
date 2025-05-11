import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/widgets/ocutune_mitid_simulated_box.dart';

class SimulatedLoginScreen extends StatelessWidget {
  final String title;
  final String inputLabel;
  final TextEditingController controller;
  final VoidCallback onContinue;

  const SimulatedLoginScreen({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.controller,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C4C4C), // darkGray
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C4C4C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SimulatedMitIDBox(
          title: 'Log på Ocutune Applikation',
          controller: controller,
          onContinue: onContinue,
        ),
      ),
    );
  }
}
