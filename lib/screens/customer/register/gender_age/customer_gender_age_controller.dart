import 'package:flutter/material.dart';
import '/services/services/user_data_service.dart';

class CustomerGenderAgeController {
  static void handleGenderAgeSubmit({
    required BuildContext context,
    required String? selectedGender,
    required String? selectedYear,
    required bool yearChosen,
  }) {
    if (!yearChosen || selectedGender == null) {
      _showError(context, "Vælg både år og køn");
      return;
    }

    if (currentUserResponse != null) {
      currentUserResponse!.gender = selectedGender;
      currentUserResponse!.birthYear = selectedYear!;
    }

    Navigator.pushNamed(context, '/chooseChronotype');
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
