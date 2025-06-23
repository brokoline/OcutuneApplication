// File: lib/widgets/universal/confirm_dialog.dart

import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Slet',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: generalBox,
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      content: Text(message, style: const TextStyle(color: Colors.white60)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuller', style: TextStyle(color: Colors.white54)),
        ),
        TextButton.icon(
          onPressed: () {
            // 1) Luk kun dialogen med `false` så dine existing .then(ok) IKKE skyder igen.
            Navigator.of(context).pop(false);
            // 2) Kør det callback, du allerede har givet (f.eks. deleteActivity).
            onConfirm();
          },
          icon: const Icon(Icons.delete, color: Colors.red),
          label: Text(confirmText, style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
