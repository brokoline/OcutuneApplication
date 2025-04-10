import 'package:flutter/material.dart';

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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle ?? const TextStyle(fontSize: 14, color: Colors.white70),
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
