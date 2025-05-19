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
      print('📛 Manglende input');
      setState(() => loginError = 'Udfyld både bruger-ID og adgangskode');
      return;
    }

    print('🔁 Sender POST til: ${ApiService.baseUrl}/sim-login');
    print('📨 Payload: $userId / $password');

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

      print('📥 Statuskode: ${response.statusCode}');
      print('📦 Svar body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Gem logininfo
        await auth.AuthStorage.saveLogin(
          id: data['id'],
          role: data['role'],
          token: data['token'],
          simUserId: data['sim_userid'],
        );

        // Gem navn til visning senere
        await auth.AuthStorage.savePatientProfile(
          firstName: data['first_name'],
          lastName: data['last_name'],
        );

        // Navigér videre
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/chooseAccess');
      }
    } catch (e) {
      print('💥 Undtagelse fanget: $e');
      setState(() => loginError = 'Netværksfejl eller server utilgængelig');
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
