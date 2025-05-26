import 'package:flutter/material.dart';
import '../../../models/patient.dart';
import '../../../services/services/api_services.dart';

class ClinicianSearchController with ChangeNotifier {
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = false;
  String? _error;
  String _currentQuery = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Patient> get filteredPatients => _filteredPatients;
  String get currentQuery => _currentQuery;

  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.fetchClinicianPatients();
      _allPatients = response.map((p) => Patient.fromJson(p)).toList();
      _filteredPatients = []; // ← tom som udgangspunkt
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void searchPatients(String query) {
    _currentQuery = query;
    print('🔍 Søgning: "$query"');

    if (query.trim().isEmpty) {
      _filteredPatients = [];
      print('⚠️ Tom søgning');
    } else {
      final lower = query.toLowerCase();
      _filteredPatients = _allPatients.where((p) {
        final fname = p.firstName.toLowerCase();
        final lname = p.lastName.toLowerCase();
        final cpr = p.cpr ?? '';
        return fname.contains(lower) || lname.contains(lower) || cpr.contains(query);
      }).toList();

      print('✅ Resultater: ${_filteredPatients.length}');
    }

  notifyListeners();
  }
}
