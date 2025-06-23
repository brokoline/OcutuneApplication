import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';

import 'customer_activity_controller.dart';

class CustomerActivityScreen extends StatefulWidget {
  const CustomerActivityScreen({super.key});

  @override
  State<CustomerActivityScreen> createState() => _CustomerActivityScreenState();
}

class _CustomerActivityScreenState extends State<CustomerActivityScreen> {
  final CustomerActivityController _controller = CustomerActivityController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    _controller.loadActivities();
    _controller.loadLabels();
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  Future<TimeOfDay?> _pickTime(String helpText) async {
    return await showTimePicker(
      context: context,
      helpText: helpText,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: generalBox,
              hourMinuteTextColor: Colors.white70,
            ),
            colorScheme: ColorScheme.dark(
              primary: Colors.white70,
              surface: generalBox,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _onConfirm() async {
    if (_controller.selected == null) return;

    final now = DateTime.now();
    final startTime = await _pickTime('Starttid');
    if (startTime == null) return;

    final endTime = await _pickTime('Sluttid');
    if (endTime == null) return;

    final start = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final end = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    await _controller.registerActivity(_controller.selected!, start, end, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Din eksisterende UI-kode her...
              if (_controller.selected != null)
                OcutuneButton(
                  text: 'Bekræft registrering',
                  onPressed: _onConfirm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}