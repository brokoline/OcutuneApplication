// lib/controller/simulated_login_controller.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart' as auth;

class SimulatedLoginController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading     => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Forsøger login med MitID-simulering.
  /// onSuccess får den pæne rolle (pretty_role) og bruger-id.
  Future<void> login({
    required String userId,
    required String password,
    required void Function(String prettyRole, String id) onSuccess,
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

        final prettyRole = (data['pretty_role'] as String?)?.trim() ?? '';

        // Gem login-info med den pæne rolle
        await auth.AuthStorage.saveLogin(
          id:         data['id'].toString(),
          role:       prettyRole,
          token:      data['token'] as String,
          simUserId:  data['sim_userid'].toString(),
          customerId: data['role'] == 'patient'
              ? int.tryParse(data['id'].toString())
              : null,
        );

        // Gem profil-navn
        if (data['role'] == 'clinician') {
          await auth.AuthStorage.saveClinicianProfile(
            firstName: data['first_name'] as String,
            lastName:  data['last_name']  as String,
          );
        } else {
          await auth.AuthStorage.savePatientProfile(
            firstName: data['first_name'] as String,
            lastName:  data['last_name']  as String,
          );
        }

        onSuccess(prettyRole, data['id'].toString());
      } else if (resp.statusCode == 401) {
        _errorMessage = 'Forkert brugernavn eller adgangskode';
      } else {
        _errorMessage = 'Serverfejl (${resp.statusCode})';
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
