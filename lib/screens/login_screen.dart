import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_textfield.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: darkGray,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo_ocutune.png',
                    width: 140,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  OcutuneTextField(
                    label: 'Email',
                    controller: emailController,
                  ),
                  const SizedBox(height: 12),
                  OcutuneTextField(
                    label: 'Password',
                    isPassword: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 16),
                  OcutuneButton(
                    text: 'Sign In',
                    onPressed: () {
                      // TODO: Handle sign-in
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Not registered? Sign up',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
