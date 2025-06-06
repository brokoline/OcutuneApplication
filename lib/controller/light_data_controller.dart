import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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

  void setData(List<LightData> newList) {
    _data = newList;
    notifyListeners();
  }

  List<BarChartGroupData> generateWeeklyBars() {
    final Map<int, List<double>> grouped = {};

    for (var entry in _data) {
      final weekday = entry.timestamp.weekday;
      grouped.putIfAbsent(weekday, () => []).add(entry.calculatedScore * 100);
    }

    return grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0, 100),
            color: avg >= 75 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> generateMonthlyBars() {
    final Map<String, List<double>> grouped = {};

    for (var entry in _data) {
      final dayKey = DateFormat('dd').format(entry.timestamp);
      grouped.putIfAbsent(dayKey, () => []).add(entry.calculatedScore * 100);
    }

    int index = 0;
    return grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0, 100),
            color: avg >= 75 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
          ),
        ],
      );
    }).toList();
  }
}
