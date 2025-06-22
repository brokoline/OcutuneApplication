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
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? loginError;

  Future<void> _attemptLogin(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      setState(() => loginError = 'Udfyld både bruger‐ID og adgangskode');
      return;
    }

    print('🔁 Sender POST til: ${ApiService.baseUrl}/api/auth/mitid/login');
    print('📨 Payload: sim_userid=$userId, sim_password=$password');

    setState(() {
      isLoading = true;
      loginError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/mitid/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sim_userid': userId,
          'sim_password': password,
        }),
      );

      print('Statuskode: ${response.statusCode}');
      print('Svar body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Gem login‐info (id, rolle, token, sim_userid)
        await auth.AuthStorage.saveLogin(
          id: data['id'],
          role: data['role'],
          token: data['token'],
          simUserId: data['sim_userid'],
        );
        // DEBUG: Bekræft at token blev gemt korrekt
        final savedToken = await auth.AuthStorage.getToken();
        print('>>> DEBUG: Gemt token i AuthStorage = $savedToken');

        // Gem navn, afhængigt af om det er clinician eller patient
        if (data['role'] == 'clinician') {
          await auth.AuthStorage.saveClinicianProfile(
            firstName: data['first_name'],
            lastName: data['last_name'],
          );
          final name = await auth.AuthStorage.getClinicianName();
          print('>>> DEBUG: Gemt kliniker navn = $name');
        } else {
          await auth.AuthStorage.savePatientProfile(
            firstName: data['first_name'],
            lastName: data['last_name'],
          );
          final fname = await auth.AuthStorage.getName();
          print('>>> DEBUG: Gemt patient navn = $fname');
        }

        if (!mounted) return;

        // Navigér baseret på rolle
        if (data['role'] == 'patient') {
          Navigator.pushReplacementNamed(
            context,
            '/patient/dashboard',
            arguments: data['id'],
          );
        } else if (data['role'] == 'clinician') {
          Navigator.pushReplacementNamed(context, '/clinician');
        } else {
          setState(() => loginError = 'Ukendt rolle: ${data['role']}');
        }
      } else {
        setState(() => loginError = 'Forkert brugernavn eller adgangskode');
      }
    } catch (e) {
      print('Undtagelse fanget: $e');
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
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 24.h,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SimulatedMitIDBox(
                title: widget.title,
                controller: userIdController,
                errorMessage: loginError,
                onContinue: (user, password) =>
                    _attemptLogin(user.trim(), password.trim()),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
