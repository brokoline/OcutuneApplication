import 'package:flutter/material.dart';

class ClinicianDashboardController extends ChangeNotifier {
  List<String> notifications = [
    'Patient X har sendt en ny besked',
    'Patient Y har registreret ny aktivitet',
    'Patient Zs lysniveau er under normalen',
  ];

  List<String> _allPatients = ['Patient X', 'Patient Y', 'Patient Z'];
  List<String> searchResults = [];

  void searchPatient(String query) {
    searchResults = _allPatients
        .where((p) => p.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }
}
