// lib/screens/customer/register/chronotype_setup/choose_chronotype_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/services/customer_data_service.dart'; // ← currentCustomerResponse her
import '/models/customer_response_model.dart';
import 'package:ocutune_light_logger/models/remq_chronotype_model.dart';

class ChooseChronotypeController {
  static const String _baseUrl = 'https://ocutune2025.ddns.net';

  static const String _path = '/api/chronotypes';
  static Future<List<Chronotype>> fetchChronotypes() async {
    final uri = Uri.parse('$_baseUrl$_path');
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data.map((j) => Chronotype.fromJson(j)).toList();
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

  /// Håndterer tryk på “Næste”: tilføjer den valgte kronotype som
  /// svar‐tekst, sætter chronotypeKey og navigerer videre.
  static void goToNextScreen(BuildContext ctx, String? selectedChronotype) {
    if (selectedChronotype == null) {
      showError(ctx, "Vælg en kronotype eller tag testen først");
      return;
    }

    final resp = currentCustomerResponse;
    if (resp == null) {
      showError(ctx, "Intern fejl: brugerdata mangler");
      return;
    }

    // Bygger et nyt CustomerResponse-objekt på baggrund af det gamle:
    currentCustomerResponse = CustomerResponse(
      firstName:     resp.firstName,
      lastName:      resp.lastName,
      email:         resp.email,
      gender:        resp.gender,
      birthYear:     resp.birthYear,
      answers:       [...resp.answers, selectedChronotype],
      questionScores: Map.from(resp.questionScores),
      rmeqScore:     resp.rmeqScore,
      meqScore:      resp.meqScore,
      chronotype: selectedChronotype,
      password:      resp.password,
    );

    Navigator.pushNamed(ctx, '/doneSetup');
  }
}
