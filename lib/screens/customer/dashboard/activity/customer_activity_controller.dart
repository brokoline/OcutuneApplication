import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/confirm_dialog.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';

class CustomerActivityController extends ChangeNotifier {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  String? selected;
  bool isLoading = false;

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
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      final data = await ApiService.fetchCustomerActivities(rawId.toString());
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
      recent.sort((a, b) => b['start'].compareTo(a['start']));
    } catch (e) {
      debugPrint('Fejl loadActivities: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLabels() async {
    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      activities = await ApiService.fetchCustomerActivityLabels(rawId.toString());
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
      _showSnack(ctx, 'Sluttid < starttid', isError: true);
      return;
    }
    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      await ApiService.addCustomerActivityEvent(
        customerId     : rawId.toString(),
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
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      await ApiService.deleteCustomerActivity(id, rawId.toString());
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
              decoration: const InputDecoration(hintText: 'F.eks. Udflugt', hintStyle: TextStyle(color: Colors.white54)),
              onChanged: (v) => newLabel = v,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OcutuneButton(
                text: 'Tilføj',
                onPressed: () async {
                  if (newLabel.trim().isEmpty) return;
                  try {
                    final rawId = await AuthStorage.getCustomerId();
                    if (rawId == null) return;
                    await ApiService.addCustomerActivityLabel(
                      customerId: rawId.toString(),
                      label     : newLabel.trim(),
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

  Future<TimeOfDay?> showStyledTimePicker(BuildContext ctx, String helpText) {
    return showTimePicker(
      context     : ctx,
      helpText    : helpText,
      initialTime : TimeOfDay.now(),
      builder     : (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor     : generalBox,
            hourMinuteTextColor : Colors.white70,
            dialHandColor       : Colors.white70,
            dayPeriodTextColor  : Colors.white70,
            helpTextStyle       : const TextStyle(color: Colors.white70),
          ),
          colorScheme: ColorScheme.dark(
            primary  : Colors.white70,
            onPrimary: Colors.black,
            surface  : generalBox,
            onSurface: Colors.white70,
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> openConfirmDialog(BuildContext ctx) async {
    final now   = DateTime.now();
    final start = await showStyledTimePicker(ctx, 'Starttidspunkt');
    if (start == null) return;
    final end = await showStyledTimePicker(ctx, 'Sluttidspunkt');
    if (end == null) return;
    final startDt = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final endDt   = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    await registerActivity(selected!, startDt, endDt, ctx);
  }

  DateTime _parseDate(String s) {
    try { return DateTime.parse(s).toLocal(); }
    on FormatException {
      try { return HttpDate.parse(s).toLocal(); }
      on FormatException {
        try { return DateFormat('EEE, dd MMM yyyy HH:mm:ss').parse(s).toLocal(); }
        catch (_) { return DateTime.now(); }
      }
    }
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
