import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_textfield.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';
import 'package:ocutune_light_logger/widgets/ocutune_card.dart';

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
        backgroundColor: lightGray,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OcutuneCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo_ocutune.png',
                        width: 140,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      OcutuneTextField(
                        label: 'E-mail',
                        controller: emailController,
                        labelStyle: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      OcutuneTextField(
                        label: 'Adgangskode',
                        isPassword: true,
                        controller: passwordController,
                        labelStyle: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      OcutuneButton(
                        text: 'Log ind',
                        onPressed: () {
                          // handle sign in
                        },
                        type: OcutuneButtonType.primary,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Glemt adgangskode?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Ikke registreret? Opret bruger',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chooseAccess');
                  },
                  child: const Text(
                    'Kliniker eller patient? Log ind her',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
