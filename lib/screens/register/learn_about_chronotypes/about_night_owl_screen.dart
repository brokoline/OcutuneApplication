import 'package:flutter/material.dart';
import '/theme/colors.dart';

class AboutNightOwlScreen extends StatelessWidget {
  const AboutNightOwlScreen({super.key});

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
              "Chronotype: Night Owl",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Image.asset("assets/images/nightowl.png", height: 60),
            const SizedBox(height: 24),
            const Text(
              "Do you feel most alive when the sun goes down?\n\nDo you get your best ideas late at night while the rest of the world sleeps?\n\nIf so, you're a Night Owl!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              "Night owls work well in times that rely on creativity in the evening and struggle with early mornings. They often do well in fields that don't require a strict morning routine.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
