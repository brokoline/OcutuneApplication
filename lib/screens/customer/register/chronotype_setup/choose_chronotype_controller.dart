// lib/screens/customer/register/chronotype_setup/choose_chronotype_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/services/customer_data_service.dart'; // ← currentCustomerResponse her
import '/models/customer_response_model.dart';
import 'package:ocutune_light_logger/models/rmeq_chronotype_model.dart';

class ChooseChronotypeController {
  static const String _baseUrl = 'https://ocutune2025.ddns.net';

  static const String _path = '/api/chronotypes';
  static Future<List<ChronotypeModel>> fetchChronotypes() async {
    final uri = Uri.parse('$_baseUrl$_path');
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data.map((j) => ChronotypeModel.fromJson(j)).toList();
    } else {
      throw Exception('Failed to load chronotypes (HTTP ${resp.statusCode})');
    }
  }
  /// Vis fejl-snackbar
  static void showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  // Håndterer tryk på “Næste”: tilføjer den valgte kronotype som
  // svar‐tekst, sætter chronotypeKey og navigerer videre.
  static Future<void> goToNextScreen(BuildContext ctx, String? selectedChronotype) async {
    if (selectedChronotype == null) {
      showError(ctx, "Vælg en kronotype eller tag testen først");
      return;
    }

    final resp = currentCustomerResponse;
    if (resp == null) {
      showError(ctx, "Intern fejl: brugerdata mangler");
      return;
    }

    try {
      final chronotypes = await fetchChronotypes();
      final chosenType = chronotypes.firstWhere(
            (type) => type.typeKey == selectedChronotype,
        orElse: () => throw Exception('Kronotype ikke fundet'),
      );

      currentCustomerResponse = CustomerResponse(
        firstName: resp.firstName,
        lastName: resp.lastName,
        email: resp.email,
        gender: resp.gender,
        birthYear: resp.birthYear,
        answers: [...resp.answers, chosenType.typeKey],
        questionScores: Map.from(resp.questionScores),
        rmeqScore: resp.rmeqScore,
        meqScore: resp.meqScore,
        chronotype: chosenType.typeKey,
        password: resp.password,
      );

      setChronotypeKey(chosenType.typeKey);

      Navigator.pushNamed(ctx, '/doneSetup');
    } catch (e) {
      showError(ctx, 'Fejl: ${e.toString()}');
    }
  }
}
