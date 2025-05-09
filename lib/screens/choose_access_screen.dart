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
                  subtitle: 'Log ind som patient med MitID',
                  color: Colors.blue,
                  onTap: () {
                    // TODO: Handle patient login
                    Navigator.pushNamed(context, '/home'); // Simuler login
                  },
                ),
                const SizedBox(height: 16),
                _accessButton(
                  context,
                  title: 'NemLog-in',
                  subtitle: 'Log ind som kliniker med NemLog-in',
                  color: Colors.indigo,
                  onTap: () {
                    // TODO: Handle clinician login
                    Navigator.pushNamed(context, '/home'); // Simuler login
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
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
    );
  }
}
