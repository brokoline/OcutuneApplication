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
      setState(() {
        activities = labels;
      });
    } catch (e) {
      debugPrint('Kunne ikke hente aktivitets-kategorier: $e');
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
        customerId: customerId,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Bekræft sletning',
        message: 'Er du sikker på, at du vil slette denne aktivitet?',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed != true) return;
    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;
      final customerId = rawId.toString();

      await ApiService.deleteCustomerActivity(id, customerId: customerId);
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
                      final rawId = await AuthStorage.getCustomerId();
                      if (rawId == null) return;
                      final customerId = rawId.toString();

                      await ApiService.addCustomerActivityLabel(
                        customerId: customerId,
                        label: newLabel.trim(),
                      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Registrér kundeaktivitet',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 20),
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
                const Text(
                  'Her kan du registrere aktiviteter, hvor kunden har været udsat for dagslys, '
                      'men ikke har haft sin lyslogger med sig.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selected,
                  decoration: InputDecoration(
                    labelText: 'Vælg aktivitet',
                    filled: true,
                    fillColor: generalBox,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  dropdownColor: generalBox,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                  onChanged: (val) => setState(() => selected = val),
                  items: activities.map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label, style: const TextStyle(color: Colors.white70)),
                  )).toList(),
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
                  OcutuneButton(text: 'Bekræft registrering', onPressed: () async {
                    final now = DateTime.now();
                    final start = await showStyledTimePicker('Starttidspunkt');
                    if (start == null) return;
                    final end = await showStyledTimePicker('Sluttidspunkt');
                    if (end == null) return;
                    await registerActivity(selected!, DateTime(now.year, now.month, now.day, start.hour, start.minute), DateTime(now.year, now.month, now.day, end.hour, end.minute));
                  })
                else
                  const SizedBox(height: 24),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Seneste registreringer', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ...recent.take(5).map((item) {
                    final start = item['start'] as DateTime;
                    final end = item['end'] as DateTime;
                    final duration = formatDuration(end.difference(start));
                    return Card(
                      color: generalBox,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(item['label'], style: const TextStyle(color: Colors.white70)),
                        subtitle: Text('$duration • ${formatDateTime(start)}', style: const TextStyle(color: Colors.white38)),
                        trailing: item['deletable'] == true ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white54),
                          onPressed: () => deleteActivity(item['id'] as int),
                        ) : null,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
