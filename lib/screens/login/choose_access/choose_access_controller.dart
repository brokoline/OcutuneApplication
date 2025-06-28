

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

enum AccessDestination { none, patientDashboard, clinicianDashboard }

class ChooseAccessController extends ChangeNotifier {
  AccessDestination _destination = AccessDestination.none;
  String? _userId;

  AccessDestination get destination => _destination;
  String? get userId => _userId;

  Future<void> checkLoginStatus() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      _destination = AccessDestination.none;
    } else {
      final role = await AuthStorage.getUserRole();
      final id   = await AuthStorage.getUserId();
      if (role == 'patient' && id != null) {
        _userId      = id;
        _destination = AccessDestination.patientDashboard;
      } else if (role == 'clinician' && id != null) {
        _destination = AccessDestination.clinicianDashboard;
      } else {
        _destination = AccessDestination.none;
      }
    }
    notifyListeners();
  }
}
