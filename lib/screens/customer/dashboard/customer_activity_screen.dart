import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../services/services/api_services.dart';
import '../../../services/auth_storage.dart';
import '../../../widgets/universal/confirm_dialog.dart';
import '../../../widgets/universal/ocutune_next_step_button.dart';

class CustomerActivityScreen extends StatefulWidget {
  const CustomerActivityScreen({super.key});

  @override
  State<CustomerActivityScreen> createState() => _CustomerActivityScreenState();
}

class _CustomerActivityScreenState extends State<CustomerActivityScreen> {
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
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      final customerId = rawId.toString();

      final labels = await ApiService.fetchCustomerActivityLabels(customerId);
      if (!mounted) return;
      setState(() => activities = labels);
    } catch (e) {
      debugPrint('Kunne ikke hente customer-labels: $e');
      // silently fail
    }
  }

  Future<void> loadActivities() async {
    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      final customerId = rawId.toString();

      final activitiesFromDb = await ApiService.fetchCustomerActivities(customerId);
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
      debugPrint('Error loading customer activities: $e');
      // silently fail
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
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      final customerId = rawId.toString();

      await ApiService.addCustomerActivityEvent(
        customerId:      customerId,
        eventType:       label,
        note:            'Manuelt registreret',
        startTime:       startTime.toIso8601String(),
        endTime:         endTime.toIso8601String(),
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
      debugPrint('Error registering customer activity: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke gemme aktivitet')),
      );
    }
  }

  Future<void> deleteActivity(int id) async {
    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      final customerId = rawId.toString();

      await ApiService.deleteCustomerActivity(
        id,
        customerId,
        // successCode: 204 is default
      );

      await loadActivities();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivitet slettet')),
      );
    } catch (e) {
      debugPrint('Error deleting customer activity: $e');
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
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
                    final customerId = rawId.toString();

                    await ApiService.addCustomerActivityLabel(
                      customerId: customerId,
                      label:      newLabel.trim(),
                    );
                    await loadActivityLabels();
                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (_) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kunne ikke tilføje type')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<TimeOfDay?> showStyledTimePicker(String helpText) {
    return showTimePicker(
      context: context,
      helpText: helpText,
      initialTime: TimeOfDay.now(),
      builder: (_, child) => Theme(
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
      ),
    );
  }

  Future<void> openConfirmDialog() async {
    if (selected == null || !mounted) return;
    final now   = DateTime.now();
    final start = await showStyledTimePicker('Starttidspunkt');
    if (start == null || !mounted) return;
    final end = await showStyledTimePicker('Sluttidspunkt');
    if (end == null || !mounted) return;

    final startDt = DateTime(now.year, now.month, now.day, start.hour,  start.minute);
    final endDt   = DateTime(now.year, now.month, now.day, end.hour,    end.minute);
    await registerActivity(selected!, startDt, endDt);
  }

  Widget buildRecentCard(Map<String, dynamic> item) {
    final DateTime start = item['start'];
    final DateTime end   = item['end'];
    final duration       = end.difference(start);

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
              Text(item['label'],
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              if (item['deletable'] == true)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white54),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => ConfirmDialog(
                        title: 'Bekræft sletning',
                        message: 'Er du sikker på, at du vil slette denne aktivitet?',
                        onConfirm: () {},
                      ),
                    );
                    if (ok == true && mounted) await deleteActivity(item['id']);
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Varighed: ${formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white70)),
              Text(formatDateTime(start),
                  style: const TextStyle(color: Colors.white38)),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                  menuMaxHeight: 320,
                  onChanged: (v) => setState(() => selected = v),
                  items: activities.isEmpty
                      ? [
                    DropdownMenuItem<String>(
                      value: null,
                      enabled: false,
                      child: Text(
                        'Ingen aktiviteter er oprettet endnu',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    )
                  ]
                      : activities.map((label) {
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Text(label,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  hint: activities.isEmpty
                      ? Text(
                    'Ingen aktiviteter er oprettet endnu',
                    style: TextStyle(color: Colors.white54),
                  )
                      : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: openNewActivityDialog,
                    icon: const Icon(Icons.add, color: Colors.white70),
                    label: const Text('Opret ny aktivitet',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 12),
                if (selected != null)
                  OcutuneButton(text: 'Bekræft registrering', onPressed: openConfirmDialog)
                else
                  const SizedBox(height: 24),
                if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Ingen aktiviteter endnu.\nTryk “Opret ny aktivitet” for at komme i gang.',
                      style: const TextStyle(color: Colors.white54, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Seneste registreringer',
                      style: TextStyle(color: Colors.white70),
                    ),
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
