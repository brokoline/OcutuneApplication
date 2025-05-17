import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OcutuneTextField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;
  final TextStyle? labelStyle;

  const OcutuneTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    required this.controller,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle ?? TextStyle(fontSize: 14.sp, color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
