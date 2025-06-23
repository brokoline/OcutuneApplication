// lib/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_textfield.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_card.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed(BuildContext context) {
    final controller = context.read<LoginController>();
    controller
        .login(
      email:    _emailController.text.trim(),
      password: _passwordController.text.trim(),
    )
        .then((success) {
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushReplacementNamed('/customerDashboard');
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
      }
    });
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: generalBox,
        title: const Text('Ups!'),
        content: const Text(
          'Det var ikke så heldigt…\n\n'
              'Lige nu kan vi desværre ikke regenerere din adgangskode, '
              'så du bliver nødt til at oprette en ny profil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

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

                // Card med logo + felter + knapper
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

                      // E‐mail‐felt
                      OcutuneTextField(
                        label:      'E‐mail',
                        controller: _emailController,
                        labelStyle: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.h),

                      // Adgangskode‐felt
                      OcutuneTextField(
                        label:      'Adgangskode',
                        isPassword: true,
                        controller: _passwordController,
                        labelStyle: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 24.h),

                      // Login‐knap
                      OcutuneButton(
                        text: controller.isLoading ? 'Logger ind…' : 'Log ind',
                        type: OcutuneButtonType.primary,
                        onPressed: () {
                          if (controller.isLoading) return;
                          _onLoginPressed(context);
                        },
                      ),

                      SizedBox(height: 8.h),

                      // Glemt adgangskode?
                      TextButton(
                        onPressed: () => _showForgotPasswordDialog(context),
                        child: Text(
                          'Glemt adgangskode?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),

                      // Opret bruger-knap
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

                SizedBox(height: 16.h),

                // Vælg Kliniker vs Patient
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
