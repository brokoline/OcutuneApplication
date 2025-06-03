// lib/widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Til at formatere DateTime → "HH:mm"

import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../../models/light_data_model.dart';
import '../../../controller/chronotype_controller.dart'; // Til ChronotypeManager
import '../../../../utils/light_data_processing.dart';      // Til kliniker-anbefalinger

import 'clinician_recommandation_card.dart';
import 'light_slide_bar_chart.dart';
import 'light_recommendations_card.dart';
import 'light_score_card.dart';

class LightSummarySection extends StatelessWidget {
  /// Patient‐ID, så vi kan videregive det til LightSlideBarChart
  final String patientId;

  /// rMEQ‐score (bruges til at beregne anbefalinger osv.)
  final int rmeqScore;

  /// Valgfri MEQ‐score (kun til ScoreCard)
  final int? meqScore;

  const LightSummarySection({
    super.key,
    required this.patientId,
    required this.rmeqScore,
    this.meqScore,
  });

  @override
  Widget build(BuildContext context) {
    // Hent viewmodel’en
    final vm = Provider.of<PatientDetailViewModel>(context, listen: true);

    // 1) Hvis vi stadig henter _rawLightData, vis loading
    if (vm.isFetchingRaw && vm.rawLightData.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Hvis der er fejl under hentning, vis fejltekst
    if (vm.rawFetchError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: Text(
            'Fejl ved hentning af lysdata: ${vm.rawFetchError}',
            style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 3) Hvis vi har hentet, men listen stadig er tom => ingen lysdata endnu
    if (!vm.isFetchingRaw && vm.rawLightData.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'Ingen lysdata registreret endnu',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<LightData> allLightData = vm.rawLightData;

    // ────────────────────────────────────────────────────────────────
    // 4) Generér kliniker-anbefalinger vha. LightDataProcessing
    final List<String> clinicianRecs = LightDataProcessing(rMEQ: rmeqScore)
        .generateAdvancedRecommendations(
      data: allLightData,
      rMEQ: rmeqScore,
    );

    // 5) Generér “almindelige” anbefalinger via ChronotypeManager (ud fra rMEQ‐score)
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final String chronoLabel = chrono.getChronotypeLabel();
    final Map<String, DateTime> timeMap = chrono.getRecommendedTimes();
    final DateFormat fmt = DateFormat('HH:mm');

    // Aflæs tidspunkter (bang-operator, da vi antager, at nøglerne findes)
    final DateTime dlmoDt          = timeMap['dlmo']!;
    final DateTime sleepStartDt    = timeMap['sleep_start']!;
    final DateTime wakeTimeDt      = timeMap['wake_time']!;
    final DateTime lightBoostStart = timeMap['lightboost_start']!;
    final DateTime lightBoostEnd   = timeMap['lightboost_end']!;

    final List<String> recs = [
      "Kronotype: $chronoLabel",
      "DLMO (Dim Light Melatonin Onset): ${fmt.format(dlmoDt)}",
      "Sengetid (DLMO + 2 timer): ${fmt.format(sleepStartDt)}",
      "Opvågning (DLMO + 10 timer): ${fmt.format(wakeTimeDt)}",
      "Light‐boost start: ${fmt.format(lightBoostStart)}",
      "Light‐boost slut: ${fmt.format(lightBoostEnd)}",
    ];
    // ────────────────────────────────────────────────────────────────

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─────── 1) VIS kliniker-anbefalinger øverst ────────────────────────
        ClinicianRecommendationCard(
          recommendations: clinicianRecs,
        ),
        SizedBox(height: 16.h),

        // ─────── 2) VIS “almindelige” anbefalinger ─────────────────────────
        LightRecommendationsCard(
          recommendations: recs,
        ),
        SizedBox(height: 16.h),

        // ─────── 3) Score card (rMEQ + MEQ) ───────────────────────────────
        LightScoreCard(
          rmeqScore: rmeqScore,
          meqScore: meqScore ?? 0,
        ),
        SizedBox(height: 24.h),

        // ─────── 4) Én samlet “slide”-graf: Dag / Uge / Måned ───────────────
        LightSlideBarChart(
          patientId: patientId,
          rmeqScore: rmeqScore,
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}
