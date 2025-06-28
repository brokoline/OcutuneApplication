import 'package:flutter/material.dart';
import '/services/services/customer_data_service.dart';

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

    final resp = currentCustomerResponse;
    if (resp != null) {
      currentCustomerResponse = resp.copyWith(
        gender:    selectedGender,
        birthYear: selectedYear!,
      );
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
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
