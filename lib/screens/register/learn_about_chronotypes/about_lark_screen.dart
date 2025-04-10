import 'package:flutter/material.dart';
import '/theme/colors.dart';

class AboutLarkScreen extends StatelessWidget {
  const AboutLarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Chronotype: Lark",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Image.asset("assets/images/lark.png", height: 60),
            const SizedBox(height: 24),
            const Text(
              "Are you the kind of person who wakes up full of energy while the rest of the world is still snoozing?\n\nIf so, you're probably a Lark!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              "Larks are early risers who thrive in the morning and love structured routines. Their energy peaks early in the day, making them perfect for jobs or activities that require early productivity.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
