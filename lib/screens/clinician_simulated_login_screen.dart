import 'package:flutter/material.dart';

class ClinicianSimulatedLoginScreen extends StatefulWidget {
  const ClinicianSimulatedLoginScreen({super.key});

  @override
  State<ClinicianSimulatedLoginScreen> createState() => _ClinicianSimulatedLoginScreenState();
}

class _ClinicianSimulatedLoginScreenState extends State<ClinicianSimulatedLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    // TODO: Send til API /sim-login
    Navigator.pushReplacementNamed(context, '/clinician/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kliniker Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
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
