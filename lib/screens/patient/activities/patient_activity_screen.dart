import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';

class PatientActivityScreen extends StatefulWidget {
  const PatientActivityScreen({super.key});


  @override
  State<PatientActivityScreen> createState() => _PatientActivityScreenState();
}

class _PatientActivityScreenState extends State<PatientActivityScreen> {
  final List<Map<String, dynamic>> recent = [];
  final List<String> activities = ['Gåtur', 'Strand', 'Indendørs', 'Andet'];
  String? selected;

  String formatDateTime(DateTime dt) => DateFormat('dd.MM • HH:mm').format(dt);

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '$hours time${hours > 1 ? 'r' : ''} og $minutes min';
    if (hours > 0) return '$hours time${hours > 1 ? 'r' : ''}';
    return '$minutes min';
  }

  void registerActivity(String label, DateTime startTime, DateTime endTime) {
    setState(() {
      recent.insert(0, {
        'label': label,
        'start': startTime,
        'end': endTime,
      });
      selected = null;

      activities.remove(label);
      activities.insert(0, label);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aktivitet "$label" registreret')),
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
              dialHandColor: Colors.white70,
              dialTextColor: Colors.white70,
              hourMinuteTextColor: Colors.white70,
              hourMinuteColor: Colors.transparent,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hourMinuteTextStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              helpTextStyle: const TextStyle(color: Colors.white),
              entryModeIconColor: Colors.white54,
              dayPeriodTextColor: Colors.white70,
              dayPeriodColor: Colors.white12,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.white70,
              onPrimary: Colors.black,
              surface: generalBox,
              onSurface: Colors.white70,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> openConfirmDialog() async {
    if (selected == null) return;

    final now = DateTime.now();

    TimeOfDay? start = await showStyledTimePicker('Hvornår startede aktiviteten ca.?');
    if (start == null) return;
    final startDateTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);

    TimeOfDay? end = await showStyledTimePicker('Hvornår sluttede aktiviteten ca.?');
    if (end == null) return;
    final endDateTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    registerActivity(selected!, startDateTime, endDateTime);
  }

  void openNewActivityDialog() {
    String newLabel = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: generalBox,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ny aktivitet', style: TextStyle(color: Colors.white)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'F.eks. Udflugt',
            hintStyle: TextStyle(color: Colors.white54),
          ),
          onChanged: (value) => newLabel = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annullér', style: TextStyle(color: Colors.white70)),
          ),
          OcutuneButton(
            text: 'Tilføj',
            onPressed: () {
              if (newLabel.trim().isEmpty) return;
              setState(() {
                activities.add(newLabel.trim());
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
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
          Text(item['label'], style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Varighed: ${formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white70)),
              Text(formatDateTime(start), style: const TextStyle(color: Colors.white38)),
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
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Registrér aktivitet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Her kan du registrere aktiviteter, hvor du har været udsat for dagslys, '
                    'men ikke har haft din lyslogger med dig – f.eks. hvis du har været på stranden, '
                    'ude og gå eller haft den glemt derhjemme.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            DropdownButtonFormField<String>(
              value: selected,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
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
              style: const TextStyle(color: Colors.white),
              menuMaxHeight: 300,
              onChanged: (val) => setState(() => selected = val),
              items: activities.map((label) {
                return DropdownMenuItem(
                  value: label,
                  child: Text(label, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: openNewActivityDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Opret ny aktivitet', style: TextStyle(color: Colors.white)),
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
              Expanded(
                child: ListView(
                  children: recent.take(5).map(buildRecentCard).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
