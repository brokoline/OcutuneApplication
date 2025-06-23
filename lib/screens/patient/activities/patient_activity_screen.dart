// File: lib/screens/patient/activities/patient_activity_screen.dart

import 'dart:io'; // til HttpDate
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../services/services/api_services.dart';
import '../../../services/auth_storage.dart';
import '../../../widgets/universal/confirm_dialog.dart';
import '../../../widgets/universal/ocutune_next_step_button.dart';

/// Formatter til SQL‐tidsformatet fra din API
final _sqlFormatter = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");

DateTime _parseDate(String s) {
  try {
    // Først prøv SQL‐format
    return _sqlFormatter.parse(s, true).toLocal();
  } on FormatException {
    // Ellers RFC1123‐format (fx "Mon, 23 Jun 2025 17:11:00 GMT")
    return HttpDate.parse(s).toLocal();
  }
}

class PatientActivityScreen extends StatefulWidget {
  const PatientActivityScreen({Key? key}) : super(key: key);

  @override
  State<PatientActivityScreen> createState() => _PatientActivityScreenState();
}

class _PatientActivityScreenState extends State<PatientActivityScreen> {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  String? selected;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([_loadActivities(), _loadActivityLabels()]);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _loadActivityLabels() async {
    try {
      final raw = await AuthStorage.getUserId();
      if (raw == null) return;
      final labels = await ApiService.fetchActivityLabels(raw.toString());
      if (!mounted) return;
      setState(() => activities = labels);
    } catch (e) {
      debugPrint('❌ loadActivityLabels error: $e');
    }
  }

  Future<void> _loadActivities() async {
    try {
      final raw = await AuthStorage.getUserId();
      if (raw == null) return;
      final list = await ApiService.fetchActivities(raw.toString());
      final parsed = list.map((a) {
        final start = _parseDate(a['start_time'] as String);
        final end   = _parseDate(a['end_time']   as String);
        return {
          'id': a['id'],
          'label': a['event_type'],
          'start': start,
          'end': end,
          'deletable': (a['note'] as String?)?.toLowerCase().contains('manuelt') ?? false,
        };
      }).toList();
      if (!mounted) return;
      setState(() => recent = parsed);
    } catch (e) {
      debugPrint('❌ loadActivities error: $e');
    }
  }

  String _fmtDate(DateTime dt) => DateFormat('dd.MM • HH:mm').format(dt);

  String _fmtDur(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '$h time${h>1?"r":""} og $m min';
    if (h > 0) return '$h time${h>1?"r":""}';
    return '$m min';
  }

  Future<void> _register(String label, DateTime start, DateTime end) async {
    final minutes = end.difference(start).inMinutes;
    try {
      final raw = await AuthStorage.getUserId();
      if (raw == null) return;
      await ApiService.addActivityEvent(
        patientId: raw.toString(),
        eventType: label,
        note: 'Manuelt registreret',
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
        durationMinutes: minutes,
      );
      await _loadActivities();
      await _loadActivityLabels();
      if (!mounted) return;
      setState(() => selected = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktivitet "$label" registreret')),
      );
    } catch (e) {
      debugPrint('❌ register error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke gemme aktivitet')),
      );
    }
  }

  Future<void> _delete(int id) async {
    try {
      final raw = await AuthStorage.getUserId();
      if (raw == null) return;
      await ApiService.deleteActivity(id, userId: raw.toString());
      await _loadActivities();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivitet slettet')),
      );
    } catch (e) {
      debugPrint('❌ delete error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke slette aktivitet')),
      );
    }
  }

  Future<TimeOfDay?> _pick(String help) {
    return showTimePicker(
      context: context,
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

  Future<void> _onConfirm() async {
    if (selected == null) return;
    final now = DateTime.now();
    final t1 = await _pick('Hvornår startede aktiviteten ca.?');
    if (t1 == null) return;
    final t2 = await _pick('Hvornår sluttede aktiviteten ca.?');
    if (t2 == null) return;
    final start = DateTime(now.year, now.month, now.day, t1.hour, t1.minute);
    final end   = DateTime(now.year, now.month, now.day, t2.hour, t2.minute);
    await _register(selected!, start, end);
  }

  void _openNewLabel() {
    String label = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: generalBox,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Wrap(runSpacing: 16, children: [
          const Text('Ny aktivitet', style: TextStyle(color: Colors.white70, fontSize: 18)),
          TextField(
            style: const TextStyle(color: Colors.white70),
            decoration: const InputDecoration(
              hintText: 'F.eks. Udflugt', hintStyle: TextStyle(color: Colors.white54),
            ),
            onChanged: (v) => label = v,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OcutuneButton(
              text: 'Tilføj',
              onPressed: () async {
                if (label.trim().isEmpty) return;
                final raw = await AuthStorage.getUserId();
                if (raw != null) {
                  await ApiService.addActivityLabel(
                    patientId: raw.toString(),
                    label: label.trim(),
                  );
                  await _loadActivityLabels();
                }
                if (!mounted) return;
                Navigator.pop(ctx);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> it) {
    final start = it['start'] as DateTime;
    final end   = it['end']   as DateTime;
    final dur   = end.difference(start);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: generalBox, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(it['label'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (it['deletable'] == true)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white54),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => ConfirmDialog(
                  title: 'Slet aktivitet?',
                  message: 'Bekræft sletning',
                  onConfirm: () => Navigator.pop(context, true),
                ),
              ).then((ok) {
                if (ok == true) _delete(it['id'] as int);
              }),
            ),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Varighed: ${_fmtDur(dur)}', style: const TextStyle(color: Colors.white70)),
          Text(_fmtDate(start), style: const TextStyle(color: Colors.white38)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: generalBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        title: const Text(
          'Aktiviteter',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: generalBackground,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Her kan du registrere aktiviteter, hvor du har været udsat for dagslys, men ikke har haft din lyslogger med dig – f.eks. hvis du har været på stranden, ude og motionere eller blot haft den glemt derhjemme.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              // Dropdown
              DropdownButtonFormField<String>(
                value: selected,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                decoration: InputDecoration(
                  labelText: 'Vælg aktivitet',
                  labelStyle: const TextStyle(color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                  filled: true,
                  fillColor: generalBox,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                dropdownColor: generalBox,
                items: activities
                    .map((lbl) => DropdownMenuItem(
                  value: lbl,
                  child: Text(lbl, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                ))
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
              ),

              const SizedBox(height: 12),

              // Opret ny aktivitet
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openNewLabel,
                  icon: const Icon(Icons.add, color: Colors.white70),
                  label: const Text('Opret ny aktivitet', style: TextStyle(color: Colors.white70)),
                ),
              ),

              const SizedBox(height: 12),

              // Bekræft registrering
              if (selected != null)
                OcutuneButton(text: 'Bekræft registrering', onPressed: _onConfirm)
              else
                const SizedBox(height: 24),

              const SizedBox(height: 20),
              const Text('Seneste registreringer', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),

              if (recent.isEmpty)
                const Center(child: Text('Ingen aktiviteter endnu.', style: TextStyle(color: Colors.white54)))
              else
                ...recent.take(5).map(_buildCard),
            ]),
          ),
        ),
      ),
    );
  }
}
