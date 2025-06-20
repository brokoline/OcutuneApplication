// lib/screens/customer/dashboard/customer_root_controller.dart
import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/models/customer_model.dart';
import 'package:ocutune_light_logger/models/rmeq_chronotype_model.dart';

class CustomerRootController extends ChangeNotifier {
  int _currentIndex = 0;
  Customer? _profile;
  ChronotypeModel? _chronoModel;
  final List<String> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  CustomerRootController() {
    _fetchProfile();
  }

  // Aktuel faneblad-indeks
  int get currentIndex => _currentIndex;

  // Profil-data
  Customer? get profile => _profile;

  // Detaljeret chronotype-model
  ChronotypeModel? get chronoModel => _chronoModel;

  // Liste med anbefalingstekster
  List<String> get recommendations => _recommendations;

  // Om vi henter data lige nu
  bool get isLoading => _isLoading;

  // Eventuel fejlbesked
  String? get error => _error;

  // Sætter den aktuelle tab‐indeks og notifikér lyttere
  void setIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Henter kundens profil + chronotype via ApiService
  Future<void> _fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.fetchCustomerProfile();
      _profile = result.first;
      _chronoModel = result.second;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}