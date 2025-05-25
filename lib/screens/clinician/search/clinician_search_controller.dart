import 'package:flutter/material.dart';
import '../../../models/patient.dart';
import '../../../services/services/api_services.dart';

class ClinicianSearchController with ChangeNotifier {
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Patient> get filteredPatients => _filteredPatients;

  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.fetchClinicianPatients();
      _allPatients = response.map((p) => Patient.fromJson(p)).toList();
      _filteredPatients = _allPatients;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void searchPatients(String query) {
    if (query.isEmpty) {
      _filteredPatients = _allPatients;
    } else {
      final lower = query.toLowerCase();
      _filteredPatients = _allPatients.where((p) {
        return p.firstName.toLowerCase().contains(lower) ||
            p.lastName.toLowerCase().contains(lower) ||
            (p.cpr?.contains(query) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}
