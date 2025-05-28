import 'package:flutter/material.dart';
import '../../models/light_data_model.dart';
import '../../services/services/api_services.dart';

class LightDataController with ChangeNotifier {
  List<LightData> _data = [];
  bool _loading = false;
  String? _error;

  List<LightData> get data => _data;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetch(String patientId) async {
    _loading = true;
    notifyListeners();

    try {
      final raw = await ApiService.getPatientLightData(patientId);
      _data = raw.map((e) => LightData.fromJson(e)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _data = [];
    }

    _loading = false;
    notifyListeners();
  }
}
