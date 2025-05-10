import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_mitid_simulated_box.dart';

class ClinicianSimulatedLoginScreen extends StatelessWidget {
  const ClinicianSimulatedLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        backgroundColor: darkGray,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MitID Erhverv Login', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SimulatedMitIDBox(
          title: 'Log på hos MitID Erhverv',
          controller: emailController,
          onContinue: () {
            // TODO: API-kald til /sim-login
            Navigator.pushReplacementNamed(context, '/clinician/dashboard');
          },
        ),
      ),
    );
  }
}
