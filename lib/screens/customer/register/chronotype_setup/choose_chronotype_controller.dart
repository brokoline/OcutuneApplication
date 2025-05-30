// lib/controllers/choose_chronotype_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/theme/colors.dart';
import '/services/services/user_data_service.dart';
import '/models/user_response_model.dart';
import 'package:ocutune_light_logger/models/chronotype_model.dart';
import '../../../../widgets/universal/ocutune_next_step_button.dart';

class ChooseChronotypeController {
  static const _endpoint = 'https://ocutune2025.ddns.net/chronotypes';

  /// Fetches the list of chronotypes from the server.
  static Future<List<Chronotype>> fetchChronotypes() async {
    final uri = Uri.parse(_endpoint);
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data.map((j) => Chronotype.fromJson(j)).toList();
    } else {
      throw Exception('Failed to load chronotypes');
    }
  }

  /// Shows an error snackbar.
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

  /// Handles the “next” logic: updates the global response and navigates.
  static void goToNextScreen(BuildContext ctx, String? selectedChronotype) {
    if (selectedChronotype != null) {
      if (currentUserResponse != null) {
        currentUserResponse = UserResponse(
          firstName: currentUserResponse!.firstName,
          lastName:  currentUserResponse!.lastName,
          email:     currentUserResponse!.email,
          password:  currentUserResponse!.password,
          gender:    currentUserResponse!.gender,
          birthYear: currentUserResponse!.birthYear,
          answers:   [...currentUserResponse!.answers, selectedChronotype],
          scores:    currentUserResponse!.scores,
        );
      }
      Navigator.pushNamed(ctx, '/doneSetup');
    } else {
      showError(ctx, "Vælg en kronotype eller tag testen først");
    }
  }
}
