import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_mitid_simulated_box.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart' as auth;

class SimulatedLoginScreen extends StatefulWidget {
  final String title;
  const SimulatedLoginScreen({ super.key, required this.title });

  @override
  State<SimulatedLoginScreen> createState() => _SimulatedLoginScreenState();
}

class _SimulatedLoginScreenState extends State<SimulatedLoginScreen> {
  final TextEditingController userIdController     = TextEditingController();
  final TextEditingController passwordController   = TextEditingController();
  bool isLoading = false;
  String? loginError;

  Future<void> _attemptLogin(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      setState(() => loginError = 'Udfyld både bruger‐ID og adgangskode');
      return;
    }

    setState(() {
      isLoading = true;
      loginError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/mitid/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sim_userid':   userId,
          'sim_password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await auth.AuthStorage.saveLogin(
          id:         data['id'],
          role:       data['role'],
          token:      data['token'],
          simUserId:  data['sim_userid'],
        );

        if (data['role'] == 'clinician') {
          await auth.AuthStorage.saveClinicianProfile(
            firstName: data['first_name'],
            lastName:  data['last_name'],
          );
        } else {
          await auth.AuthStorage.savePatientProfile(
            firstName: data['first_name'],
            lastName:  data['last_name'],
          );
        }

        if (!mounted) return;

        if (data['role'] == 'patient') {
          Navigator.pushReplacementNamed(
            context,
            '/patient/dashboard',
            arguments: data['id'],
          );
        } else {
          Navigator.pushReplacementNamed(context, '/clinician');
        }
      } else {
        setState(() => loginError = 'Forkert brugernavn eller adgangskode');
      }
    } catch (e) {
      setState(() => loginError = 'Netværksfejl eller server utilgængelig');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: generalBackground,
        foregroundColor: Colors.white70,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SimulatedMitIDBox(
                title:              widget.title,
                controller:         userIdController,
                passwordController: passwordController,
                isLoading:          isLoading,
                errorMessage:       loginError,
                onContinue: (user, pass) =>
                    _attemptLogin(user.trim(), pass.trim()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isLoading
          ? Container(
        color: const Color.fromRGBO(0, 0, 0, 0.3),
        child: const Center(child: CircularProgressIndicator()),
      )
          : null,
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
    );
  }
}
