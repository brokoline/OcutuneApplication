import 'package:flutter/material.dart';

class PatientSimulatedLoginScreen extends StatefulWidget {
  const PatientSimulatedLoginScreen({super.key});

  @override
  State<PatientSimulatedLoginScreen> createState() => _PatientSimulatedLoginScreenState();
}

class _PatientSimulatedLoginScreenState extends State<PatientSimulatedLoginScreen> {
  final _cprController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    // TODO: Send til API /sim-login
    Navigator.pushReplacementNamed(context, '/patient/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _cprController,
              decoration: const InputDecoration(labelText: 'CPR-nummer'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Adgangskode'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Log ind'),
            ),
          ],
        ),
      ),
    );
  }
}
