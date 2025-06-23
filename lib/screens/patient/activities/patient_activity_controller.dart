// File: lib/screens/patient/activities/patient_activity_controller.dart

import 'dart:io';                   // <-- import til HttpDate
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/services/api_services.dart';
import '../../../services/auth_storage.dart';

/// Matcher “2025-05-18 16:30:00.000”
final _sqlFormatter = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");

DateTime parseSql(String dbValue) {
  try {
    // Prøv SQL-format først
    return _sqlFormatter.parse(dbValue, true).toLocal();
  } on FormatException {
    // Fallback: Date header fra API (RFC1123)
    return HttpDate.parse(dbValue).toLocal();
  }
}

class PatientActivityController extends ChangeNotifier {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  bool isLoading = false;
  String? _selected;

  String? get selected => _selected;
  set selected(String? v) {
    _selected = v;
    notifyListeners();
  }

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      loadLabels(),
      loadActivities(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadLabels() async {
    final userId = await AuthStorage.getUserId();
    if (userId == null) return;
    try {
      activities = await ApiService.fetchActivityLabels(userId.toString());
      notifyListeners();
    } catch (e) {
      debugPrint('loadLabels error: $e');
    }
  }

  Future<void> addLabel(String label) async {
    final userId = await AuthStorage.getUserId();
    if (userId == null) return;
    try {
      await ApiService.addActivityLabel(
        patientId: userId.toString(),
        label: label,
      );
      await loadLabels();
    } catch (e) {
      debugPrint('addLabel error: $e');
    }
  }

  Future<void> loadActivities() async {
    final userId = await AuthStorage.getUserId();
    if (userId == null) return;
    try {
      final list = await ApiService.fetchActivities(userId.toString());
      debugPrint('🔄 rawActivities: $list');
      recent = list.map((a) {
        final start = parseSql(a['start_time'] as String);
        final end   = parseSql(a['end_time']   as String);
        return {
          'id': a['id'],
          'label': a['event_type'],
          'start': start,
          'end': end,
          'deletable': (a['note'] as String?)?.toLowerCase().contains('manuelt') ?? false,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadActivities error: $e');
    }
  }

  Future<void> registerActivity(DateTime start, DateTime end) async {
    final label = _selected;
    if (label == null) return;
    final duration = end.difference(start).inMinutes;
    final userId = await AuthStorage.getUserId();
    if (userId == null) return;
    try {
      await ApiService.addActivityEvent(
        patientId: userId.toString(),
        eventType: label,
        note: 'Manuelt registreret',
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
        durationMinutes: duration,
      );
      _selected = null;
      await loadActivities();
      notifyListeners();
    } catch (e) {
      debugPrint('registerActivity error: $e');
      rethrow;
    }
  }

  Future<void> deleteActivity(int id) async {
    final userId = await AuthStorage.getUserId();
    if (userId == null) return;
    try {
      await ApiService.deleteActivity(id, userId: userId.toString());
      await loadActivities();
      notifyListeners();
    } catch (e) {
      debugPrint('deleteActivity error: $e');
      rethrow;
    }
  }
}
