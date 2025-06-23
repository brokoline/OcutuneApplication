// lib/widgets/universal/login_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// En speciallavet login-knap med diskret, lys grå gradient og loading-state.
class LoginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Højde på knap
  final double height;

  /// Radius for hjørner
  final double borderRadius;

  /// Farvegradient (lys grå)
  final Gradient gradient;

  /// Skygge-styrke
  final double elevation;

  const LoginButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48.0,
    this.borderRadius = 24.0,
    this.elevation = 4.0,
    // Lysere gråtonet standard-gradient
    this.gradient = const LinearGradient(
      colors: [
        Color(0xFFB0B0B0), // øverste, lys grå
        Color(0xFF828282), // nederste, medium grå
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.w,       // smallere knap
      height: height.h,   // fast højde
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: elevation.r,
              offset: Offset(0, elevation / 2),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.r),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation(Colors.white70),
              ),
            )
                : Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
