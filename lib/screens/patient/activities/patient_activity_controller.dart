import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/confirm_dialog.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';

class PatientActivityController extends ChangeNotifier {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  String? selected;
  bool isLoading = false;

  // 1) Dato-parser som fallback på flere formater
  DateTime _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString).toLocal();
    } on FormatException {
      try {
        return HttpDate.parse(dateString).toLocal();
      } on FormatException {
        try {
          final fmt = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
          return fmt.parse(dateString).toLocal();
        } catch (_) {
          debugPrint('Kunne ikke parse dato: $dateString');
          return DateTime.now();
        }
      }
    }
  }

  void setSelected(String? v) {
    selected = v;
    notifyListeners();
  }

  Future<void> init() async {
    await Future.wait([_loadActivities(), _loadLabels()]);
  }

  Future<void> _loadActivities() async {
    isLoading = true;
    notifyListeners();
    try {
      final rawId = await AuthStorage.getUserId();
      if (rawId == null) return;
      final data = await ApiService.fetchActivities(rawId.toString());
      recent = data.map((a) {
        final start = _parseDate(a['start_time'] as String);
        final end   = _parseDate(a['end_time']   as String);
        return {
          'id'       : a['id'],
          'label'    : a['event_type'] ?? 'Ukendt',
          'start'    : start,
          'end'      : end,
          'deletable': (a['note'] as String?)?.toLowerCase().contains('manuelt') ?? false,
        };
      }).toList();
      // 2) Sortér seneste først
      recent.sort((a, b) => b['start'].compareTo(a['start']));
      notifyListeners();
    } catch (e) {
      debugPrint('Fejl loadActivities: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLabels() async {
    try {
      final rawId = await AuthStorage.getUserId();
      if (rawId == null) return;
      activities = await ApiService.fetchActivityLabels(rawId.toString());
      notifyListeners();
    } catch (e) {
      debugPrint('Fejl loadLabels: $e');
    }
  }

  Future<void> registerActivity(
      String label,
      DateTime start,
      DateTime end,
      BuildContext ctx,
      ) async {
    if (label.isEmpty) {
      _showSnack(ctx, 'Vælg en aktivitetstype', isError: true);
      return;
    }
    final dur = end.difference(start);
    if (dur <= Duration.zero) {
      _showSnack(ctx, 'Sluttid skal være efter starttid', isError: true);
      return;
    }
    try {
      final rawId = await AuthStorage.getUserId();
      if (rawId == null) return;
      await ApiService.addActivityEvent(
        patientId      : rawId.toString(),
        eventType      : label,
        note           : 'Manuelt registreret',
        startTime      : start.toIso8601String(),
        endTime        : end.toIso8601String(),
        durationMinutes: dur.inMinutes,
      );
      selected = null;
      await Future.wait([_loadActivities(), _loadLabels()]);
      _showSnack(ctx, 'Aktivitet "$label" registreret (${dur.inMinutes}m)');
    } catch (e) {
      _showSnack(ctx, 'Kunne ikke gemme aktivitet', isError: true);
      debugPrint('Fejl register: $e');
    }
  }

  Future<void> deleteActivity(int id, BuildContext ctx) async {
    try {
      final rawId = await AuthStorage.getUserId();
      if (rawId == null) return;
      await ApiService.deleteActivity(id, userId: rawId.toString());
      await _loadActivities();
      _showSnack(ctx, 'Aktivitet slettet');
    } catch (e) {
      _showSnack(ctx, 'Kunne ikke slette aktivitet', isError: true);
      debugPrint('Fejl delete: $e');
    }
  }

  Future<void> confirmDelete(int id, BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => ConfirmDialog(
        title: 'Bekræft sletning',
        message: 'Vil du slette denne aktivitet?',
        onConfirm: () {},
      ),
    );
    if (ok == true) deleteActivity(id, ctx);
  }

  Future<void> openNewActivityDialog(BuildContext ctx) async {
    String newLabel = '';
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: generalBox,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20, right: 20, top: 20,
        ),
        child: Wrap(
          runSpacing: 16,
          children: [
            const Text('Ny aktivitet', style: TextStyle(color: Colors.white70, fontSize: 18)),
            TextField(
              style: const TextStyle(color: Colors.white70),
              decoration: const InputDecoration(
                hintText: 'F.eks. Udflugt', hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
              onChanged: (v) => newLabel = v,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OcutuneButton(
                text: 'Tilføj',
                onPressed: () async {
                  if (newLabel.trim().isEmpty) return;
                  try {
                    final rawId = await AuthStorage.getUserId();
                    if (rawId == null) return;
                    await ApiService.addActivityLabel(
                      patientId: rawId.toString(),
                      label    : newLabel.trim(),
                    );
                    await _loadLabels();
                    Navigator.pop(ctx);
                  } catch (_) {
                    Navigator.pop(ctx);
                    _showSnack(ctx, 'Kunne ikke tilføje type', isError: true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<TimeOfDay?> showCustomTimePicker(BuildContext context, String title, String confirmText) async {
    TimeOfDay? selectedTime;
    final now = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: generalBox,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 280,
              color: generalBox,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: Duration(hours: now.hour, minutes: now.minute),
                        minuteInterval: 1,
                        onTimerDurationChanged: (Duration duration) {
                          setState(() {
                            selectedTime = TimeOfDay(
                              hour: duration.inHours % 24,
                              minute: duration.inMinutes % 60,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text('Annuller', style: TextStyle(color: Colors.white70)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: Text(confirmText, style: const TextStyle(color: Colors.white70)),
                          onPressed: () {
                            Navigator.pop(context, selectedTime ?? now);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return selectedTime ?? now;
  }

  Future<void> openConfirmDialog(BuildContext ctx) async {
    final now = DateTime.now();

    final start = await showCustomTimePicker(ctx, 'Starttidspunkt', 'OK');
    if (start == null) return;

    final end = await showCustomTimePicker(ctx, 'Slut tidspunkt', 'Gem');
    if (end == null) return;

    final startDt = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final endDt = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    await registerActivity(selected!, startDt, endDt, ctx);
  }

  void _showSnack(BuildContext ctx, String msg, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
        );
      }
    });
  }
}
