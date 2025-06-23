import 'dart:io'; // til HttpDate.parse
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../services/services/api_services.dart';
import '../../../services/auth_storage.dart';

/// Formatter til SQL‐tidsformat fra API’en
final _sqlFormatter = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");

DateTime _parseDate(String s) {
  try {
    return _sqlFormatter.parse(s, true).toLocal();
  } on FormatException {
    return HttpDate.parse(s).toLocal();
  }
}

class PatientActivityController extends ChangeNotifier {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  bool isLoading = false;
  String? selected;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    await Future.wait([_loadLabels(), _loadActivities()]);
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLabels() async {
    final raw = await AuthStorage.getUserId();
    if (raw == null) return;
    try {
      activities = await ApiService.fetchActivityLabels(raw.toString());
      // Sortér labels efter seneste brugstid:
      final lastUsed = <String, DateTime>{};
      for (var e in recent) {
        final lbl = e['label'] as String;
        final dt  = e['start'] as DateTime;
        if (!lastUsed.containsKey(lbl) || dt.isAfter(lastUsed[lbl]!)) {
          lastUsed[lbl] = dt;
        }
      }
      activities.sort((a, b) {
        final da = lastUsed[a], db = lastUsed[b];
        if (da != null && db != null) return db.compareTo(da);
        if (da != null) return -1;
        if (db != null) return 1;
        return a.compareTo(b);
      });
    } catch (e) {
      debugPrint('❌ loadLabels error: $e');
    }
    notifyListeners();
  }

  Future<void> _loadActivities() async {
    final raw = await AuthStorage.getUserId();
    if (raw == null) return;
    try {
      final list = await ApiService.fetchActivities(raw.toString());
      recent = list.map((a) {
        final start = _parseDate(a['start_time'] as String);
        final end   = _parseDate(a['end_time']   as String);
        return {
          'id'       : a['id'],
          'label'    : a['event_type'],
          'start'    : start,
          'end'      : end,
          'deletable': (a['note'] as String?)?.toLowerCase().contains('manuelt') ?? false,
        };
      }).toList();
      recent.sort((a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));
    } catch (e) {
      debugPrint('❌ loadActivities error: $e');
    }
    notifyListeners();
  }

  void select(String? value) {
    selected = value;
    notifyListeners();
  }

  Future<void> registerActivity(DateTime start, DateTime end) async {
    if (selected == null) return;
    final raw = await AuthStorage.getUserId();
    if (raw == null) return;
    final minutes = end.difference(start).inMinutes;
    try {
      await ApiService.addActivityEvent(
        patientId: raw.toString(),
        eventType: selected!,
        note: 'Manuelt registreret',
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
        durationMinutes: minutes,
      );
      selected = null;
      await Future.wait([_loadActivities(), _loadLabels()]);
    } catch (e) {
      debugPrint('❌ registerActivity error: $e');
    }
    notifyListeners();
  }

  Future<void> deleteActivity(int id) async {
    final raw = await AuthStorage.getUserId();
    if (raw == null) return;
    try {
      await ApiService.deleteActivity(id, userId: raw.toString());
      await _loadActivities();
    } catch (e) {
      debugPrint('❌ deleteActivity error: $e');
    }
    notifyListeners();
  }
}
