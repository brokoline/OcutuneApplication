import 'package:flutter/material.dart';
import '../../../models/patient_model.dart';
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
      final response = await ApiService.getClinicianPatients();
      _allPatients = response.map((p) => Patient.fromJson(p)).toList();
      _filteredPatients = []; // tom som udgangspunkt
      _error = null;
    } catch (e) {
      _error = e.toString();
    }


    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchPatients(String query) async {
    _currentQuery = query;
    print('🔍 Backend-søgning: "$query"');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.searchPatients(query);
      _filteredPatients = response.map((p) => Patient.fromJson(p)).toList();
      _error = null;
      print('✅ Resultater: ${_filteredPatients.length}');
    } catch (e) {
      _error = e.toString();
      print('❌ Fejl i søgning: $_error');
      _filteredPatients = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
