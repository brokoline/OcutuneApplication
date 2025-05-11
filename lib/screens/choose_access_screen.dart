import 'package:flutter/material.dart';
import '/theme/colors.dart';
import 'package:ocutune_light_logger/screens/simulated_mitid_login_screen.dart';

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SimulatedLoginScreen(
                          title: 'MitID Privat Login',
                          inputLabel: 'BRUGER-ID',
                          controller: TextEditingController(),
                          onContinue: () {
                            Navigator.pushReplacementNamed(context, '/patient/dashboard');
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _accessButton(
                  context,
                  title: 'MitID Erhverv',
                  subtitle: 'Log ind som kliniker med MitID Erhverv',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SimulatedLoginScreen(
                          title: 'MitID Erhverv Login',
                          inputLabel: 'BRUGER-ID',
                          controller: TextEditingController(),
                          onContinue: () {
                            Navigator.pushReplacementNamed(context, '/clinician/dashboard');
                          },
                        ),
                      ),
                    );
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
          color: color.withAlpha((255 * 0.9).round()),
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
