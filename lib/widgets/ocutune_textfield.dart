import 'package:flutter/material.dart';

class OcutuneTextField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;

  const OcutuneTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    required this.controller, // ← her er den vigtige del
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
