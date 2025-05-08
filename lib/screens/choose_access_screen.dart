import 'package:flutter/material.dart';
import '/theme/colors.dart';

class ChooseAccessScreen extends StatelessWidget {
  const ChooseAccessScreen({super.key});

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hvordan vil du logge ind?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _accessButton(
                  context,
                  title: 'MitID',
                  subtitle: 'Log ind som patient',
                  imageUrl: 'https://ocutune.ddns.net/images/mitid.png',
                  onTap: () {
                    // TODO: Handle patient login
                    Navigator.pushNamed(context, '/home');
                  },
                ),
                const SizedBox(height: 16),
                _accessButton(
                  context,
                  title: 'MitID Erhverv',
                  subtitle: 'Log ind som kliniker',
                  imageUrl: 'https://ocutune.ddns.net/images/mitid_erhverv.png',
                  onTap: () {
                    // TODO: Handle clinician login
                    Navigator.pushNamed(context, '/home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accessButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String imageUrl,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Image.network(
              imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
