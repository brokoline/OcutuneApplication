import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/models/patient.dart'; // ← Juster path hvis nødvendigt

class ClinicianDashboardController extends ChangeNotifier {
  List<String> _notifications = [];
  List<Patient> _allPatients = [];
  List<Patient> _searchResults = [];
  Patient? _selectedPatient;

  List<String> get notifications => _notifications;
  List<Patient> get searchResults => _searchResults;
  List<Patient> get allPatients => _allPatients;
  Patient? get selectedPatient => _selectedPatient;

  Future<void> loadInitialData() async {
    // Simuler API kald
    await Future.delayed(const Duration(milliseconds: 500));

    _notifications = [
      'Patient X har sendt en ny besked',
      'Patient Y har registreret ny aktivitet',
      'Patient Zs lysniveau er under normalen',
    ];

    // Brug Patient model
    _allPatients = [
      Patient(
        id: 1,
        firstName: 'Anders',
        lastName: 'And',
        cpr: '1234567890',
        simUserid: '1234',
      ),
      Patient(
        id: 2,
        firstName: 'Børge',
        lastName: 'Børgesen',
        cpr: '0987654321',
        simUserid: '1234',
      ),
      Patient(
        id: 3,
        firstName: 'Carla',
        lastName: 'Carlsen',
        cpr: '4567890123',
        simUserid: '9012',
      ),
    ];

    notifyListeners();
  }

  void selectPatient(Patient patient) {
    _selectedPatient = patient;
    notifyListeners();
  }


  Future<void> refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  void searchPatient(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _allPatients.where((patient) =>
      patient.firstName.toLowerCase().contains(query.toLowerCase()) ||
          patient.lastName.toLowerCase().contains(query.toLowerCase()) ||
          (patient.cpr ?? '').contains(query)
      ).toList();
    }
    notifyListeners();
  }

  Future<void> loadPatientDetails(int patientId) async {
    // Simuler API kald for at hente detaljer
    await Future.delayed(const Duration(milliseconds: 300));

    _selectedPatient = _allPatients.firstWhere(
          (patient) => patient.id == patientId,
      orElse: () => throw Exception('Patient ikke fundet'),
    );

    notifyListeners();
  }

  void handleNotificationTap(int index) {
    debugPrint('Notifikation trykket: ${_notifications[index]}');
    // Her kunne du implementere navigation til relevant patient
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
