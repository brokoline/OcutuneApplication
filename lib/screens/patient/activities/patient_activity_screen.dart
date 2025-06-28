import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../../widgets/universal/ocutune_next_step_button.dart';
import 'patient_activity_controller.dart';

class PatientActivityScreen extends StatelessWidget {
  const PatientActivityScreen({super.key});

  String _formatDateTime(DateTime dt) => DateFormat('dd.MM • HH:mm').format(dt);
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '$h t $m m';
    if (h > 0) return '$h t';
    return '$m m';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientActivityController()..init(),
      child: _PatientActivityView(
        formatDateTime : _formatDateTime,
        formatDuration : _formatDuration,
      ),
    );
  }
}

class _PatientActivityView extends StatelessWidget {
  final String Function(DateTime) formatDateTime;
  final String Function(Duration) formatDuration;

  const _PatientActivityView({
    required this.formatDateTime,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PatientActivityController>();

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Aktiviteter',
          style: TextStyle(
              color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Her kan du registrere aktiviteter, hvor du har været udsat for dagslys, '
                      'men ikke har haft din lyslogger med dig - f.eks. på stranden, ude og motionere '
                      'eller blot haft den glemt derhjemme.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Dropdown med max 5 items
                DropdownButtonFormField<String>(
                  value: ctrl.selected,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                  dropdownColor: generalBox,
                  isExpanded: true,
                  menuMaxHeight: 5 * 48.0,
                  decoration: InputDecoration(
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
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  items: ctrl.activities
                      .map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ))
                      .toList(),
                  onChanged: ctrl.setSelected,
                  hint: const Text('Vælg aktivitet', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () => ctrl.openNewActivityDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white70),
                  label: const Text('Opret ny aktivitet', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 12),

                if (ctrl.selected != null)
                  OcutuneButton(
                    text: 'Bekræft registrering',
                    onPressed: () => ctrl.openConfirmDialog(context),
                  ),

                const SizedBox(height: 24),
                if (ctrl.recent.isEmpty)
                  const Center(
                    child: Text(
                      'Ingen aktiviteter endnu.\nTryk “Opret ny aktivitet” for at komme i gang.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  const Text('Seneste registreringer', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ...ctrl.recent.take(5).map((item) {
                    final start    = item['start'] as DateTime;
                    final end      = item['end']   as DateTime;
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
                              Text(item['label'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                              if (item['deletable'] == true)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white54),
                                  onPressed: () => ctrl.confirmDelete(item['id'] as int, context),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Varighed: ${formatDuration(duration)}', style: const TextStyle(color: Colors.white70)),
                              Text(formatDateTime(start), style: const TextStyle(color: Colors.white38)),
                            ],
                          ),
                        ],
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
