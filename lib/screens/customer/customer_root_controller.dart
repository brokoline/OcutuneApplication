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
    fetchProfile();
  }

  int get currentIndex => _currentIndex;
  Customer? get profile => _profile;
  ChronotypeModel? get chronoModel => _chronoModel;
  List<String> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final result = await ApiService.fetchCustomerProfile();
      _profile     = result.first;
      _chronoModel = result.second;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
