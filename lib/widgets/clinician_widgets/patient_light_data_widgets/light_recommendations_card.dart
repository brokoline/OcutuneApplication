// lib/widgets/clinician_widgets/patient_light_data_widgets/light_recommendations_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../../controller/chronotype_controller.dart';

/// Dette kort viser anbefalinger baseret på:
///   1) rMEQ‐ og eventuelt gemt MEQ‐score fra Patient‐objektet (ViewModel),
///   2) Bearbejdet ML‐output (ProcessedLightData) for gårsdagens lysdata.
///
class LightRecommendationsCard extends StatelessWidget {
  const LightRecommendationsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Hent PatientDetailViewModel med Provider
    final vm = context.watch<PatientDetailViewModel>();

    // 2) Hvis der er en fejl fra ML‐bearbejdning, vis fejltekst
    if (vm.error != null) {
      return Card(
        color: Colors.red.shade700,
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            'Fejl i anbefalinger: ${vm.error}',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
        ),
      );
    }

    // 3) Hvis vi stadig er ved at behandle ML (isProcessing i ViewModel), vis spinner
    if (vm.isProcessing) {
      return Card(
        color: generalBox,
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 16.w),
              Text(
                'Beregn anbefalinger…',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    // 4) Hent det bearbejdede resultat fra ViewModel (kan være null, hvis ingen data fra i går)
    final processed = vm.processedLightData;

    // 5) Start en liste af string‐anbefalinger
    final List<String> recommendations = [];

    // 6) Chronotype‐baserede generelle anbefalinger:
    //    Brug rMEQ (int) direkte, og estimer MEQ (double) hvis storedMeqScore mangler.
    final int rmeq = vm.rmeqScore.toInt();
    final double meqValue = (vm.storedMeqScore != null)
        ? vm.storedMeqScore!.toDouble()
        : ChronotypeManager(rmeq).meqScore;
    recommendations.add(
        'Din rMEQ‐score er $rmeq, svarende til en estimeret MEQ på ${meqValue.toStringAsFixed(1)}.'
    );

    // 7) Hvis vi har et bearbejdet ML‐resultat, tilføj ML‐anbefalinger:
    if (processed != null) {
      // ─── Eksempel 1: MEDI‐værdi + tidspunkt ─────────────────────────
      final String mediValue = processed.medi.toStringAsFixed(1);
      final String mediTime = DateFormat('HH:mm').format(
        processed.timestamp.subtract(processed.mediDuration).toLocal(),
      );
      recommendations.add(
          'I går opnåede du MEDI $mediValue kl. $mediTime.'
      );

      // ─── Eksempel 2: F‐threshold‐procent ─────────────────────────────
      final String fThreshPct = (processed.fThreshold * 100).toStringAsFixed(0);
      recommendations.add(
          'F‐threshold var $fThreshPct % af værdier over tærskel.'
      );

      // ─── Eksempel 3: Bright light‐terapi i dag ──────────────────────
      // Vi vælger f.eks. 07:00–08:00 som anbefalet slot:
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String brightFrom = _formatTime(DateTime.now(), hours: 7);
      final String brightTo   = _formatTime(DateTime.now(), hours: 8);
      recommendations.add(
          'Få mindst 30 min bright light mellem kl. $brightFrom–$brightTo i dag.'
      );

      // ─── Eksempel 4: Dim light før DLMO ─────────────────────────────
      // Som eksempel: dim light fra kl. 20:00.
      recommendations.add(
          'Mørkelys (dim light) fra kl. 20:00 for optimal DLMO.'
      );
    } else {
      // Hvis ingen data fra i går:
      recommendations.add('Der var ingen lysdata fra i går at bearbejde.');
    }

    // 8) Byg UI: én række pr. anbefaling (brug pære‐ikon for hver linje)
    return Card(
      color: generalBox,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overskrift
            Text(
              "Anbefalinger",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),

            // Én række per streng i recommendations
            ...recommendations.map((r) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white70,
                      size: 18.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Hjælpefunktion til at formatere tid som “HH:mm” baseret på i dag
  String _formatTime(DateTime reference, {required int hours, int minutes = 0}) {
    final dt = DateTime(
      reference.year,
      reference.month,
      reference.day,
      hours,
      minutes,
    );
    return DateFormat('HH:mm').format(dt);
  }
}
