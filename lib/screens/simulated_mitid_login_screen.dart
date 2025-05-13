import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_storage.dart';
import '/theme/colors.dart';
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

        final role = data['role']?.toString() ?? '';
        final id = int.tryParse(data['id'].toString()) ?? 0;
        final firstName = data['first_name']?.toString() ?? '';
        final lastName = data['last_name']?.toString() ?? '';
        final simUserId = data['sim_userid']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();

        await AuthStorage.saveLoggedInUser(
          id: id,
          role: role,
          name: fullName,
          simUserId: simUserId,
        );

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
    } catch (e, stackTrace) {
      print('❌ Login-fejl: $e');
      print('📍 Stacktrace: $stackTrace');
      setState(() => loginError = 'Netværksfejl under login');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'MitID Privat Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/logo/logo_ocutune.png',
                  height: 110,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SimulatedMitIDBox(
                  title: 'Log på Ocutune Applikation',
                  controller: userIdController,
                  errorMessage: loginError,
                  onContinue: _attemptLogin,
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
