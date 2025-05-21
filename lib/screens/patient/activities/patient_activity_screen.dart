import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';
import '../../../services/services/api_services.dart';
import '../../../services/auth_storage.dart';
import '../../../widgets/confirm_dialog.dart';

class PatientActivityScreen extends StatefulWidget {
  const PatientActivityScreen({super.key});

  @override
  State<PatientActivityScreen> createState() => _PatientActivityScreenState();
}

class _PatientActivityScreenState extends State<PatientActivityScreen> {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  String? selected;

  @override
  void initState() {
    super.initState();
    loadActivities();
    loadActivityLabels();
  }

  Future<void> loadActivityLabels() async {
    try {
      final labels = await ApiService.fetchActivityLabels();
      if (!mounted) return;
      setState(() {
        activities = labels;
      });
    } catch (e) {
      debugPrint('Kunne ikke hente labels: $e');
    }
  }

  Future<void> loadActivities() async {
    try {
      final patientId = await AuthStorage.getUserId();
      if (patientId == null) return;

      final activitiesFromDb = await ApiService.fetchActivities(patientId);
      if (!mounted) return;

      setState(() {
        recent = activitiesFromDb.map((a) {
          final start = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime.now();
          final end = DateTime.tryParse(a['end_time'] ?? '') ?? start;

          return {
            'id': a['id'],
            'label': a['event_type'],
            'start': start,
            'end': end,
            'source': a['note']?.contains('Manuelt') == true ? 'manual' : 'auto',
            'deletable': a['note']?.toLowerCase().contains('manuelt') ?? false,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }
  }

  String formatDateTime(DateTime dt) => DateFormat('dd.MM • HH:mm').format(dt);

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '$hours time${hours > 1 ? 'r' : ''} og $minutes min';
    if (hours > 0) return '$hours time${hours > 1 ? 'r' : ''}';
    return '$minutes min';
  }

  Future<void> registerActivity(String label, DateTime startTime, DateTime endTime) async {
    final duration = endTime.difference(startTime).inMinutes;

    try {
      final int? patientId = await AuthStorage.getUserId();
      if (patientId == null) return;

      await ApiService.addActivityWithTimes(
        patientId: patientId,
        eventType: label,
        note: 'Manuelt registreret',
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        durationMinutes: duration,
      );

      await loadActivities();
      await loadActivityLabels();

      if (!mounted) return;
      setState(() => selected = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktivitet "$label" registreret')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke gemme aktivitet')),
      );
    }
  }

  Future<void> deleteActivity(int id) async {
    try {
      final userId = await AuthStorage.getUserId();
      if (userId == null) return;

      await ApiService.deleteActivity(id, userId: userId.toString());
      await loadActivities();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivitet slettet')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke slette aktivitet')),
      );
    }
  }

  void openNewActivityDialog() {
    String newLabel = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: generalBox,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Wrap(
            runSpacing: 16,
            children: [
              const Text(
                'Ny aktivitet',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              TextField(
                style: const TextStyle(color: Colors.white70),
                decoration: const InputDecoration(
                  hintText: 'F.eks. Udflugt',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                onChanged: (value) => newLabel = value,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OcutuneButton(
                  text: 'Tilføj',
                  onPressed: () async {
                    if (newLabel.trim().isEmpty) return;
                    try {
                      await ApiService.addActivityLabel(newLabel.trim());
                      await loadActivityLabels();
                      if (!mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kunne ikke tilføje aktivitetstype')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> showStyledTimePicker(String helpText) {
    return showTimePicker(
      context: context,
      helpText: helpText,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: generalBox,
              hourMinuteTextColor: Colors.white70,
              dialHandColor: Colors.white70,
              dayPeriodTextColor: Colors.white70,
              helpTextStyle: const TextStyle(color: Colors.white70),
            ),
            colorScheme: ColorScheme.dark(
              primary: Colors.white70,
              onPrimary: Colors.black,
              surface: generalBox,
              onSurface: Colors.white70,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> openConfirmDialog() async {
    if (selected == null || !mounted) return;

    final now = DateTime.now();

    final start = await showStyledTimePicker('Hvornår startede aktiviteten ca.?');
    if (start == null || !mounted) return;
    final startDateTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);

    final end = await showStyledTimePicker('Hvornår sluttede aktiviteten ca.?');
    if (end == null || !mounted) return;
    final endDateTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    await registerActivity(selected!, startDateTime, endDateTime);
  }

  Widget buildRecentCard(Map<String, dynamic> item) {
    final start = item['start'] as DateTime;
    final end = item['end'] as DateTime;
    final duration = end.difference(start);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: generalBox,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['label'],
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              if (item['deletable'] == true)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white54),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        title: 'Bekræft sletning',
                        message: 'Er du sikker på, at du vil slette denne aktivitet?',
                        onConfirm: () {},
                      ),
                    );
                    if (confirmed == true && mounted) {
                      await deleteActivity(item['id']);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Varighed: ${formatDuration(duration)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                formatDateTime(start),
                style: const TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Registrér aktivitet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Her kan du registrere aktiviteter, hvor du har været udsat for dagslys, '
                        'men ikke har haft din lyslogger med dig - f.eks. hvis du har været på stranden, '
                        'ude og motionere eller blot haft den glemt derhjemme.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selected,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                  dropdownColor: generalBox,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Vælg aktivitet',
                    labelStyle: const TextStyle(color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: generalBox,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white70),
                  menuMaxHeight: 300,
                  onChanged: (val) => setState(() => selected = val),
                  items: activities.map((label) {
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color.fromRGBO(255, 255, 255, 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            if (selected == label)
                              const Icon(Icons.check, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: openNewActivityDialog,
                    icon: const Icon(Icons.add, color: Colors.white70),
                    label: const Text('Opret ny aktivitet', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 12),
                if (selected != null)
                  OcutuneButton(
                    text: 'Bekræft registrering',
                    onPressed: openConfirmDialog,
                  )
                else
                  const SizedBox(height: 24),
                if (recent.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Seneste registreringer', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  ...recent.take(5).map(buildRecentCard),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
