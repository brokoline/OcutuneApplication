import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/universal/confirm_dialog.dart';
import '../../../widgets/universal/ocutune_next_step_button.dart';
import 'patient_activity_controller.dart';

class PatientActivityScreen extends StatelessWidget {
  const PatientActivityScreen({Key? key}) : super(key: key);

  String _fmtDate(DateTime dt) =>
      DateFormat('dd.MM • HH:mm').format(dt);

  String _fmtDur(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '$h time${h>1?"r":""} og $m min';
    if (h > 0) return '$h time${h>1?"r":""}';
    return '$m min';
  }

  Widget _buildCard(BuildContext ctx, Map<String, dynamic> it) {
    final start = it['start'] as DateTime;
    final end   = it['end']   as DateTime;
    final dur   = end.difference(start);
    final ctrl  = ctx.read<PatientActivityController>();

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
              Text(it['label'],
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              if (it['deletable'] == true)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white54),
                  onPressed: () {
                    showDialog<bool>(
                      context: ctx,
                      builder: (_) => ConfirmDialog(
                        title: 'Slet aktivitet?',
                        message: 'Bekræft sletning',
                        onConfirm: () {
                          // Denne kaldes EFTER at dialogen lukker
                          ctrl.deleteActivity(it['id'] as int);
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Varighed: ${_fmtDur(dur)}',
                  style: const TextStyle(color: Colors.white70)),
              Text(_fmtDate(start),
                  style: const TextStyle(color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PatientActivityController>();

    if (ctrl.isLoading) {
      return const Scaffold(
        backgroundColor: generalBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        title: const Text('Aktiviteter',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18, fontWeight: FontWeight.w600,
            )),
        backgroundColor: generalBackground,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
                        'men ikke har haft din lyslogger med dig – f.eks. hvis du har været på stranden, '
                        'ude og motionere eller blot haft den glemt derhjemme.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),

                // Dropdown
                DropdownButtonFormField<String>(
                  value: ctrl.selected,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                  decoration: InputDecoration(
                    labelText: 'Vælg aktivitet',
                    labelStyle: const TextStyle(color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                    filled: true, fillColor: generalBox,
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
                  items: ctrl.activities
                      .map((lbl) => DropdownMenuItem(
                    value: lbl,
                    child: Text(lbl,
                        style: const TextStyle(color: Colors.white70, fontSize: 18)),
                  ))
                      .toList(),
                  onChanged: ctrl.select,
                ),

                const SizedBox(height: 12),

                // Opret ny aktivitet
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => ctrl.openNewActivityDialog(context),
                    icon: const Icon(Icons.add, color: Colors.white70),
                    label: const Text('Opret ny aktivitet',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),

                const SizedBox(height: 12),

                // Bekræft registrering
                if (ctrl.selected != null)
                  OcutuneButton(
                    text: 'Bekræft registrering',
                    onPressed: () => ctrl.openRegisterDialog(context),
                  )
                else
                  const SizedBox(height: 24),

                const SizedBox(height: 20),
                const Text('Seneste registreringer',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),

                if (ctrl.recent.isEmpty)
                  const Center(
                    child: Text('Ingen aktiviteter endnu.',
                        style: TextStyle(color: Colors.white54)),
                  )
                else
                  ...ctrl.recent.take(5).map((it) => _buildCard(context, it)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
