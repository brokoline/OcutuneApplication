import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_textfield.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_card.dart';
import '../../widgets/universal/ocutune_login_button.dart';
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

  void _showForgotDialog(BuildContext context) {
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
          child: Column(
            children: [
              // Top‐link
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/chooseAccess'),
                    child: Text(
                      'Kliniker eller patient?\n Log ind her',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20.h),
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

                            OcutuneTextField(
                              label:      'E‐mail',
                              controller: _emailController,
                              labelStyle: TextStyle(fontSize: 16.sp),
                            ),
                            SizedBox(height: 16.h),

                            OcutuneTextField(
                              label:      'Adgangskode',
                              isPassword: true,
                              controller: _passwordController,
                              labelStyle: TextStyle(fontSize: 16.sp),
                            ),
                            SizedBox(height: 24.h),

                            LoginButton(
                              text:      controller.isLoading ? 'Logger ind…' : 'Log ind',
                              isLoading: controller.isLoading,
                              onPressed: controller.isLoading
                                  ? null
                                  : () => _onLoginPressed(context),
                            ),
                            SizedBox(height: 16.h),


                            TextButton(
                              onPressed: () => _showForgotDialog(context),
                              child: Text(
                                'Glemt adgangskode?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
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
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
