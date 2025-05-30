// lib/screens/customer/register/gender_age/customer_gender_age_controller.dart

import 'package:flutter/material.dart';
import '/services/services/customer_data_service.dart';

class CustomerGenderAgeController {
  /// Validér år og køn, opdater customerResponse immutabelt via copyWith, og navigér videre.
  static void handleGenderAgeSubmit({
    required BuildContext context,
    required String? selectedGender,
    required String? selectedYear,
    required bool yearChosen,
  }) {
    // Tjek at både år og køn er valgt
    if (!yearChosen || selectedGender == null) {
      _showError(context, "Vælg både år og køn");
      return;
    }

    // Opdater immutable CustomerResponse med nye værdier
    final resp = currentCustomerResponse;
    if (resp != null) {
      currentCustomerResponse = resp.copyWith(
        gender:    selectedGender,
        birthYear: selectedYear!,
      );
    }

    // Gå videre til kronotype-setup
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
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
