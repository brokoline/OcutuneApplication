// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_textfield.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_card.dart';
import '../../services/services/api_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Udfyld både e-mail og adgangskode')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(email, password);
      setState(() {
        _isLoading = false;
      });

      if (result["success"] == true) {
        final token = result["token"] as String;
        final user = result["user"] as Map<String, dynamic>;
        // TODO: Gem token i SecureStorage, hvis du skal bruge den senere:
        // await SecureStorage.write(key: "jwt_token", value: token);

        // Naviger videre til “customer”-root-skærmen. Husk at den er defineret i main.dart
        Navigator.of(context).pushReplacementNamed(
          '/customer',
          arguments: user,
        );
      } else {
        final msg = result["message"] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Netværksfejl: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: generalBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 50.h),
                OcutuneCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo/logo_ocutune.png',
                        width: 100.w,
                        color: Colors.white70,
                      ),
                      SizedBox(height: 32.h),
                      // E-mail-felt
                      OcutuneTextField(
                        label: 'E-mail',
                        controller: emailController,
                        labelStyle: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.h),
                      // Adgangskode-felt
                      OcutuneTextField(
                        label: 'Adgangskode',
                        isPassword: true,
                        controller: passwordController,
                        labelStyle: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 24.h),

                      // Login-knap
                      OcutuneButton(
                        text: _isLoading ? 'Logger ind…' : 'Log ind',
                        onPressed: () {
                          if (_isLoading) return;
                          _handleLogin();
                        },
                        type: OcutuneButtonType.primary,
                      ),

                      SizedBox(height: 1.h),
                      TextButton(
                        onPressed: () {
                          // TODO: “Glemt adgangskode” logik
                        },
                        child: Text(
                          'Glemt adgangskode?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Ikke registreret? Opret bruger',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chooseAccess');
                  },
                  child: Text(
                    'Kliniker eller patient? Log ind her',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
