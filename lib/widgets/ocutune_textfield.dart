import 'package:flutter/material.dart';

class OcutuneTextField extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool expands;
  final bool obscureText;

  /// Alias for obscureText to support legacy usage
  final bool? isPassword;

  const OcutuneTextField({
    super.key,
    required this.label,
    this.labelStyle,
    required this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.expands = false,
    this.obscureText = false,
    this.isPassword,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveObscureText = isPassword ?? obscureText;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: effectiveObscureText,
      maxLines: expands ? null : maxLines,
      expands: expands,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
