import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class LoginController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {

    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Udfyld både e‐mail og adgangskode';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      final result = await ApiService.customerLogin(email, password);

      if (result['success'] == true) {
        final token = result['token'] as String;
        final user  = result['user'] as Map<String, dynamic>;

        final customerId = user['id'] as int;
        final userId     = customerId.toString();

        await AuthStorage.saveLogin(
          id:         userId,
          role:       '',
          simUserId:  '',
          token:      token,
          customerId: customerId,
        );

        _errorMessage = null;
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Ukendt fejl';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Netværksfejl: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
