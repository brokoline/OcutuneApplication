// lib/screens/login/choose_access_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/screens/login/simuleret_mitID_login/simulated_mitid_login_screen.dart';
import 'choose_access_controller.dart';

class ChooseAccessScreen extends StatefulWidget {
  const ChooseAccessScreen({super.key});

  @override
  State<ChooseAccessScreen> createState() => _ChooseAccessScreenState();
}

class _ChooseAccessScreenState extends State<ChooseAccessScreen> {
  @override
  void initState() {
    super.initState();
    // ask controller to check login
    context.read<ChooseAccessController>().checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ChooseAccessController>();

    // react to destination changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (ctrl.destination) {
        case AccessDestination.patientDashboard:
          Navigator.pushReplacementNamed(
            context,
            '/patient/dashboard',
            arguments: ctrl.userId,
          );
          break;
        case AccessDestination.clinicianDashboard:
          Navigator.pushReplacementNamed(context, '/clinician');
          break;
        case AccessDestination.none:
        // stay on this screen
          break;
      }
    });

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Hvordan vil du logge ind?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/logo/logo_ocutune.png',
                height: 110,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              child: Column(
                children: [
                  _accessButton(
                    context,
                    title: 'MitID',
                    subtitle: 'Log ind som patient med MitID',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SimulatedLoginScreen(
                            title: 'MitID Privat Login',
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
                          builder: (_) => const SimulatedLoginScreen(
                            title: 'MitID Erhverv Login',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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
                color: Colors.white70,
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
