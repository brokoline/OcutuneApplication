import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/services/customer_data_service.dart';
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


    currentCustomerResponse = resp.copyWith(
      answers: [selectedChronotype],
      chronotype: selectedChronotype,
      questionScores: {},
      rmeqScore: null,
      meqScore: null,
    );

    Navigator.pushNamed(ctx, '/doneSetup');
  }
}
