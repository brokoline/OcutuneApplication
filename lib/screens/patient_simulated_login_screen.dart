import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_mitid_simulated_box.dart';

class PatientSimulatedLoginScreen extends StatelessWidget {
  const PatientSimulatedLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cprController = TextEditingController();

    return Scaffold(
      backgroundColor: darkGray, // din definerede baggrund
      appBar: AppBar(
        backgroundColor: darkGray,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MitID Privat Login', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SimulatedMitIDBox(
          title: 'Log på Ocutune Applikation',
          controller: cprController,
          onContinue: () {
            // TODO: API-kald til /sim-login
            Navigator.pushReplacementNamed(context, '/patient/dashboard');
          },
        ),
      ),
    );
  }
}
