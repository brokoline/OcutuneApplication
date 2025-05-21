import 'package:flutter/material.dart';

class ClinicianDashboardController extends ChangeNotifier {
  List<String> _notifications = [];
  List<String> _allPatients = [];
  List<String> _searchResults = [];

  List<String> get notifications => _notifications;
  List<String> get searchResults => _searchResults;
  List<String> get allPatients => _allPatients;

  Future<void> loadInitialData() async {
    // Simuler API kald
    await Future.delayed(const Duration(milliseconds: 500));

    _notifications = [
      'Patient X har sendt en ny besked',
      'Patient Y har registreret ny aktivitet',
      'Patient Zs lysniveau er under normalen',
    ];

    _allPatients = ['Patient X', 'Patient Y', 'Patient Z'];
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1)); // Simuler refresh
    notifyListeners();
  }

  void searchPatient(String query) {
    _searchResults = _allPatients
        .where((p) => p.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  void handleNotificationTap(int index) {
    // Implementer navigation baseret på notifikationstype
    debugPrint('Notifikation trykket: ${_notifications[index]}');
  }

  void addNotification(String message) {
    _notifications.insert(0, message);
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}