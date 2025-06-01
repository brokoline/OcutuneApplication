// lib/widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Til at formatere DateTime → "HH:mm"

import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';             // Til groupBy…-hjælpemetoder
import '../../../controller/chronotype_controller.dart'; // Til ChronotypeManager

import 'light_slide_bar_chart.dart';
import 'light_recommendations_card.dart';
import 'light_score_card.dart';
import 'light_latest_events_list.dart';

class LightSummarySection extends StatelessWidget {
  final List<LightData> data;
  final int rmeqScore;
  final int? meqScore;

  const LightSummarySection({
    Key? key,
    required this.data,
    required this.rmeqScore,
    this.meqScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'Ingen lysdata registreret endnu',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),
      );
    }

    // … evt. andre beregninger (weekMap, spots osv.) men de er ikke nødvendige, hvis du kun bruger LightSlideBarChart …

    // ────────────────────────────────────────────────────────────────
    // 4) Generér anbefalinger via ChronotypeManager (ud fra rMEQ‐score)
    //    HER bruger vi bang‐operator (!), fordi vi antager, at timeMap['dlmo'] ALDRIG er null.

    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final String chronoLabel = chrono.getChronotypeLabel();
    final Map<String, DateTime> timeMap = chrono.getRecommendedTimes();
    final DateFormat fmt = DateFormat('HH:mm');

    // Vi aflæser “dlmo” og de andre tidspunkter med “!”
    final DateTime dlmoDt          = timeMap['dlmo']!;          // Assert: key “dlmo” findes
    final DateTime sleepStartDt    = timeMap['sleep_start']!;   // Assert: key “sleep_start” findes
    final DateTime wakeTimeDt      = timeMap['wake_time']!;     // Assert: key “wake_time” findes
    final DateTime lightBoostStart = timeMap['lightboost_start']!; // Assert: key “lightboost_start” findes
    final DateTime lightBoostEnd   = timeMap['lightboost_end']!;   // Assert: key “lightboost_end” findes

    final List<String> recs = [
      "Kronotype: $chronoLabel",
      "DLMO (Dim Light Melatonin Onset): ${fmt.format(dlmoDt)}",
      "Sengetid (DLMO + 2 timer): ${fmt.format(sleepStartDt)}",
      "Opvågning (DLMO + 10 timer): ${fmt.format(wakeTimeDt)}",
      "Light‐boost start: ${fmt.format(lightBoostStart)}",
      "Light‐boost slut: ${fmt.format(lightBoostEnd)}",
    ];
    // ────────────────────────────────────────────────────────────────

    // 5) Hent processedResult fra ViewModel for at afgøre visning af recommendations
    final processedResult =
        Provider.of<PatientDetailViewModel>(context, listen: false).processedLightData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─────── 1) Recommendations card ─────────────────────────
        if (processedResult != null ||
            Provider.of<PatientDetailViewModel>(context).isProcessing ||
            Provider.of<PatientDetailViewModel>(context).error != null) ...[
          LightRecommendationsCard(recommendations: recs),
          SizedBox(height: 16.h),
        ],

        // ─────── 2) Score card (rMEQ + MEQ) ──────────────────────
        LightScoreCard(
          rmeqScore: rmeqScore,
          meqScore: meqScore ?? 0,
        ),
        SizedBox(height: 24.h),

        // ─────── 3) Én samlet “slide”-graf: Dag / Uge / Måned ───────
        LightSlideBarChart(
          rawData: data,
          rmeqScore: rmeqScore,
        ),
        SizedBox(height: 24.h),

        // ─────── 4) Seneste events liste ──────────────────────────
        LightLatestEventsList(lightData: data),
      ],
    );
  }
}
