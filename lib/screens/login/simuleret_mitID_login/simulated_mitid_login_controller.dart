// lib/controller/simulated_login_controller.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart' as auth;

enum SimulatedLoginRole { patient, clinician }

class SimulatedLoginController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Forsøger login med MitID-simulering.
  Future<void> login({
    required String userId,
    required String password,
    required void Function(String role, String id) onSuccess,
  }) async {
    if (userId.isEmpty || password.isEmpty) {
      _errorMessage = 'Udfyld både bruger-ID og adgangskode';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/auth/mitid/login');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sim_userid':   userId,
          'sim_password': password,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        // Gem login-info
        await auth.AuthStorage.saveLogin(
          id:        data['id'].toString(),
          role:      data['role'],
          token:     data['token'],
          simUserId: data['sim_userid'].toString(),
          customerId: data['role'] == 'patient' ? int.parse(data['id'].toString()) : null,
        );

        // Gem profil-navn
        if (data['role'] == 'clinician') {
          await auth.AuthStorage.saveClinicianProfile(
            firstName: data['first_name'],
            lastName:  data['last_name'],
          );
        } else {
          await auth.AuthStorage.savePatientProfile(
            firstName: data['first_name'],
            lastName:  data['last_name'],
          );
        }

        onSuccess(data['role'] as String, data['id'].toString());
      } else {
        _errorMessage = 'Forkert brugernavn eller adgangskode';
      }
    } catch (e) {
      _errorMessage = 'Netværksfejl eller server utilgængelig';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
