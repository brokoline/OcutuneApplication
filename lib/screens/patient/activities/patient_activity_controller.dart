import 'dart:io'; // til HttpDate.parse
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/services/api_services.dart';
import '../../../services/auth_storage.dart';
import '../../../theme/colors.dart';
import '../../../widgets/universal/ocutune_next_step_button.dart';
import '../../../widgets/universal/confirm_dialog.dart';

/// Formatter til SQL‐tidsformatet fra din API
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

  /// Initialiser: load labels + events
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([ _loadLabels(), _loadActivities() ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLabels() async {
    final raw = await AuthStorage.getUserId();
    if (raw == null) return;
    try {
      activities = await ApiService.fetchActivityLabels(raw.toString());
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
        // Pars event_timestamp fra API
        final ts    = a['event_timestamp'] != null
            ? _parseDate(a['event_timestamp'] as String)
            : end; // fallback
        return {
          'id'            : a['id'],
          'label'         : a['event_type'],
          'start'         : start,
          'end'           : end,
          'timestamp'     : ts,
          'deletable'     : (a['note'] as String?)?.toLowerCase().contains('manuelt') ?? false,
        };
      }).toList();

      // Sortér descending på event_timestamp
      recent.sort((a, b) {
        return (b['timestamp'] as DateTime)
            .compareTo(a['timestamp'] as DateTime);
      });
    } catch (e) {
      debugPrint('❌ loadActivities error: $e');
    }
    notifyListeners();
  }


  void select(String? v) {
    selected = v;
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
      await Future.wait([ _loadActivities(), _loadLabels() ]);
      selected = null;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ registerActivity error: $e');
    }
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
  }

  /// Picker dialog
  Future<TimeOfDay?> _pickTime(BuildContext ctx, String help) {
    return showTimePicker(
      context: ctx,
      helpText: help,
      initialTime: TimeOfDay.now(),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          timePickerTheme: TimePickerThemeData(backgroundColor: generalBox),
          colorScheme: ColorScheme.dark(
            primary: Colors.white70,
            onSurface: Colors.white70,
            surface: generalBox,
          ),
        ),
        child: child!,
      ),
    );
  }

  /// Åbn dialog til ny label
  Future<void> openNewActivityDialog(BuildContext ctx) async {
    String newLabel = '';
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: generalBox,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (inner) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(inner).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Wrap(runSpacing: 16, children: [
          const Text('Ny aktivitet',
              style: TextStyle(color: Colors.white70, fontSize: 18)),
          TextField(
            style: const TextStyle(color: Colors.white70),
            decoration: const InputDecoration(
              hintText: 'F.eks. Udflugt',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            onChanged: (v) => newLabel = v,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OcutuneButton(
              text: 'Tilføj',
              onPressed: () async {
                if (newLabel.trim().isEmpty) return;
                final raw = await AuthStorage.getUserId();
                if (raw != null) {
                  await ApiService.addActivityLabel(
                    patientId: raw.toString(),
                    label: newLabel.trim(),
                  );
                  await _loadLabels();
                }
                if (inner.mounted) Navigator.pop(inner);
              },
            ),
          ),
        ]),
      ),
    );
  }

  /// Åbn picker til registrering
  Future<void> openRegisterDialog(BuildContext ctx) async {
    if (selected == null) return;
    final now = DateTime.now();
    final t1 = await _pickTime(ctx, 'Hvornår startede aktiviteten ca.?');
    if (t1 == null) return;
    final t2 = await _pickTime(ctx, 'Hvornår sluttede aktiviteten ca.?');
    if (t2 == null) return;

    final start = DateTime(now.year, now.month, now.day, t1.hour, t1.minute);
    final end   = DateTime(now.year, now.month, now.day, t2.hour, t2.minute);

    await registerActivity(start, end);
  }
}
