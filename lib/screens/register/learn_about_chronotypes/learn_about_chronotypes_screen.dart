import 'package:flutter/material.dart';
import '/theme/colors.dart';

class LearnAboutChronotypesScreen extends StatelessWidget {
  const LearnAboutChronotypesScreen({super.key});

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Wanna learn more about\n the different chronotypes?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.info_outline, size: 36, color: Colors.white60),
                  const SizedBox(height: 16),
                  const Text(
                    "Did you know that your chronotype not only\n"
                        "affects your sleep – but also when you\n"
                        "are most creative and productive?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildChronoCard(context, title: "Lark", route: "/learnLark"),
                  _buildChronoCard(context, title: "Dove", route: "/learnDove"),
                  _buildChronoCard(context, title: "Night Owl", route: "/learnNightOwl"),
                  const SizedBox(height: 32),
                  const Text(
                    "Even presidents and famous entrepreneurs\n"
                        "plan their day according to their biological clock!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChronoCard(BuildContext context, {
    required String title,
    required String route,
  }) {
    final imageMap = {
      "Lark": "assets/images/lark.png",
      "Dove": "assets/images/dove.png",
      "Night Owl": "assets/images/nightowl.png",
    };

    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          highlightColor: Colors.white12,
          splashColor: Colors.transparent,
          onTap: () => Navigator.pushNamed(context, route),
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  imageMap[title]!,
                  height: 24,
                  width: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
