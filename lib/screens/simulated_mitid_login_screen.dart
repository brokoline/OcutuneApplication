import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ocutune_light_logger/widgets/ocutune_mitid_simulated_box.dart';

class SimulatedLoginScreen extends StatefulWidget {
  final String title;

  const SimulatedLoginScreen({
    super.key,
    required this.title,
  });

  @override
  State<SimulatedLoginScreen> createState() => _SimulatedLoginScreenState();
}

class _SimulatedLoginScreenState extends State<SimulatedLoginScreen> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? loginError;

  Future<void> _attemptLogin(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      setState(() => loginError = 'Udfyld både bruger-ID og adgangskode');
      return;
    }

    setState(() {
      isLoading = true;
      loginError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://ocutune.ddns.net/sim-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sim_userid': userId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];

        if (role == 'patient') {
          Navigator.pushReplacementNamed(context, '/patient/dashboard');
        } else if (role == 'clinician') {
          Navigator.pushReplacementNamed(context, '/clinician/dashboard');
        } else {
          setState(() => loginError = 'Ukendt rolle: $role');
        }
      } else if (response.statusCode == 403) {
        setState(() => loginError = 'Forkert adgangskode.');
      } else {
        setState(() => loginError = 'Login fejlede. Prøv igen.');
      }
    } catch (e) {
      setState(() => loginError = 'Netværksfejl under login');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C4C4C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C4C4C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          children: [
            SimulatedMitIDBox(
              title: 'Log på Ocutune Applikation',
              controller: userIdController,
              errorMessage: loginError,
              onContinue: _attemptLogin,
            ),
            if (isLoading)
              Container(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
