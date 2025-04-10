import 'package:flutter/material.dart';
import '/theme/colors.dart';

class AboutDoveScreen extends StatelessWidget {
  const AboutDoveScreen({super.key});

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
              "Chronotype: Dove",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Image.asset("assets/images/dove.png", height: 60),
            const SizedBox(height: 24),
            const Text(
              "Not a hardcore morning person but also not a night owl?\n\nIf you feel like you're somewhere in between, then you're probably a Dove!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              "Doves are the most balanced chronotype, adapting well to both early and late schedules. They have a steady energy flow throughout the day, making them well-suited for 9-to-5 routines.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
