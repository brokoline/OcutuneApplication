import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ocutune_light_logger/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      body: Center(
        child: Image.asset(
          'assets/logo_ocutune.png',
          width: 200,
          color: Colors.white,
        ),
      ),
    );
  }
}
