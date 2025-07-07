import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/services/customer_data_service.dart';
import 'package:ocutune_light_logger/models/rmeq_chronotype_model.dart';

class ChooseChronotypeController {
  static const String _baseUrl = 'https://ocutune2025.ddns.net';
  static const String _path = '/api/chronotypes';

  /// Henter chronotype‐valg fra backend
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

  /// Viser fejlbesked i app‐UI
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

  /// Navigerer videre og gemmer brugerens valgt chronotype (manuelt valgt)
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

    // estimeret rMEQ-score baseret på valgt type
    final estimatedRmeq = _estimateRmeqScore(selectedChronotype);

    currentCustomerResponse = resp.copyWith(
      answers: [selectedChronotype],
      chronotype: selectedChronotype,
      questionScores: {},
      rmeqScore: estimatedRmeq,
      meqScore: null, // Optional: udfyld hvis du vil konvertere rmeq → meq
    );

    Navigator.pushNamed(ctx, '/doneSetup');
  }

  // Returnerer en estimeret rMEQ‐score baseret på valgt chronotype‐nøgle
  static int _estimateRmeqScore(String chronotypeKey) {
    switch (chronotypeKey) {
      case 'lark':
        return 22; // gennemsnit af 18–25
      case 'dove':
        return 14; // gennemsnit af 12–17
      case 'nightowl':
        return 8;  // gennemsnit af 4–11
      default:
        return 14;
    }
  }
}
