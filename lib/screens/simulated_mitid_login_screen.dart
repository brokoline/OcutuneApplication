import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_mitid_simulated_box.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart' as auth;

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
        Uri.parse('${ApiService.baseUrl}/sim-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sim_userid': userId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];

        await auth.AuthStorage.saveLogin(
          id: data['id'],
          role: role,
          token: data['token'],
          simUserId: data['sim_userid'],
        );
        await auth.AuthStorage.setPatientId(data['id']);

        if (role == 'patient') {
          await auth.AuthStorage.savePatientProfile(
            firstName: data['first_name'],
            lastName: data['last_name'],
          );

          Navigator.pushReplacementNamed(
            context,
            '/patient/dashboard',
            arguments: data['id'], // 👈 patientId sendes her
          );
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
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: generalBackground,
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: keyboardVisible ? 24.h : 80.h,
            bottom: keyboardVisible ? 24.h : 40.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!keyboardVisible)
                Column(
                  children: [
                    SizedBox(height: 24.h),
                  ],
                ),
              SimulatedMitIDBox(
                title: widget.title,
                controller: userIdController,
                errorMessage: loginError,
                onContinue: (user, password) => _attemptLogin(
                  user.trim(),
                  password.trim(),
                ),
              ),
            ],
          ),
        ),
      ),
      // Loader-overlay
      floatingActionButton: isLoading
          ? Container(
        color: const Color.fromRGBO(0, 0, 0, 0.3),
        child: const Center(child: CircularProgressIndicator()),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
