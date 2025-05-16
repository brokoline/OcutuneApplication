import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum OcutuneButtonType {
  primary,
  secondary,
  floatingIcon,
}

class OcutuneButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final OcutuneButtonType type;

  const OcutuneButton({
    super.key,
    this.text = '',
    required this.onPressed,
    this.type = OcutuneButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final BorderSide? borderSide;

    switch (type) {
      case OcutuneButtonType.primary:
        backgroundColor = Colors.white70;
        textColor = Colors.black;
        borderSide = null;
        break;
      case OcutuneButtonType.secondary:
        backgroundColor = darkGray;
        textColor = Colors.white70;
        borderSide = const BorderSide(color: Colors.white70, width: 1);
        break;
      case OcutuneButtonType.floatingIcon:
        return FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.white70,
          foregroundColor: Colors.black,
          onPressed: onPressed,
          child: const Icon(Icons.arrow_forward),
        );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide ?? BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
