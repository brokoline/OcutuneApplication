// lib/widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../models/light_data_model.dart';
import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../utils/light_utils.dart'; // Her ligger LightDataProcessing

import 'light_recommendations_card.dart';
import 'light_score_card.dart';
import 'light_daily_line_chart.dart';
import 'light_weekly_bar_chart.dart';
import 'light_latest_events_list.dart';

class LightSummarySection extends StatelessWidget {
  /// Optræder nu **uden** parametre i constructoren,
  /// fordi vi henter alt via ViewModel/Provider i stedet.
  const LightSummarySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hent ViewModel’en direkte fra Provider
    final vm = context.watch<PatientDetailViewModel>();

    // Hent rå lysdata
    final List<LightData> data = vm.rawLightData;
    final int rmeqScore = vm.rmeqScore.toInt();

    // Hvis der slet ingen data er, vis blot placeholder-tekst
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

    // ----------------------------------------------------------
    // 1) Generér anbefalinger med LightDataProcessing
    // ----------------------------------------------------------
    final LightDataProcessing processor = LightDataProcessing(rMEQ: rmeqScore);

    // Metoden generateAdvancedRecommendations i din version tager kun
    // `data` og `rMEQ` som påkrævede parametre:
    final List<String> recs = processor.generateAdvancedRecommendations(
      data: data,
      rMEQ: rmeqScore,
    );

    // ----------------------------------------------------------
    // 2) Udregn ugentlige søjle-data og månedlige søjle-data
    // ----------------------------------------------------------
    // (i) Udregn “lux per dag” ved at kalde groupLuxByWeekdayName:
    final Map<String, double> weekMap = processor.groupLuxByWeekdayName(data);

    // (ii) Byg en liste af BarChartGroupData til ugentlig visning
    final List<BarChartGroupData> weeklyBars = _generateWeeklyBars(data);

    // (iii) Byg en liste af BarChartGroupData til månedlig visning
    final List<BarChartGroupData> monthlyBars = _generateMonthlyBars(data);

    // ----------------------------------------------------------
    // 3) Byg datapunkter til den daglige (line)graf
    // ----------------------------------------------------------
    final List<FlSpot> spots = data.map((d) {
      final local = d.timestamp.toLocal();
      final double x = local.hour + (local.minute / 60.0);
      return FlSpot(x, d.ediLux);
    }).toList();

    // ----------------------------------------------------------
    // 4) Returnér hele oversigten i én kolonne
    // ----------------------------------------------------------
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ────────────────────────────────────────────────
        // 1) Anbefalinger (kun hvis ML-resultat eller error eller stadig processer)
        // ────────────────────────────────────────────────
        if (vm.processedLightData != null || vm.error != null || vm.isProcessing) ...[
          LightRecommendationsCard(recommendations: recs),
          SizedBox(height: 16.h),
        ],

        // ────────────────────────────────────────────────
        // 2) Score‐kort: rMEQ + gemt MEQ‐score (må ske i LightScoreCard)
        // ────────────────────────────────────────────────
        LightScoreCard(
          rmeqScore: rmeqScore,
          meqScore: vm.storedMeqScore ?? 0,
        ),
        SizedBox(height: 24.h),

        // ────────────────────────────────────────────────
        // 3) Daglig linje‐graf (EDI‐procenter over døgnet)
        // ────────────────────────────────────────────────
        LightDailyLineChart(
          lightData: spots,
          totalScore: rmeqScore,
          weeklyBars: weeklyBars,
          monthlyBars: monthlyBars,
        ),
        SizedBox(height: 24.h),

        // ────────────────────────────────────────────────
        // 4) Ugentlig lyseksponerings‐søjlediagram
        // ────────────────────────────────────────────────
        LightWeeklyBarChart(luxPerDay: weekMap),
        SizedBox(height: 24.h),

        // ────────────────────────────────────────────────
        // 5) “Seneste målinger” (10 firkantede rækkefelter)
        // ────────────────────────────────────────────────
        LightLatestEventsList(lightData: data),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Hjælpefunktion: generér BarChartGroupData til ugentlig visning
  // ─────────────────────────────────────────────────────────────
  List<BarChartGroupData> _generateWeeklyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (var e in entries) {
      final int wd = e.timestamp.toLocal().weekday; // 1=mandag … 7=søndag
      grouped.putIfAbsent(wd, () => []).add(e.ediLux);
    }

    return grouped.entries.map((entry) {
      final int dayIndex = entry.key; // x‐værdien (1…7)
      final List<double> vals = entry.value;
      final double avg = vals.reduce((a, b) => a + b) / vals.length;

      return BarChartGroupData(
        x: dayIndex,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0.0, 100.0),
            color: avg >= 75.0 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
            width: 12.w,
            borderRadius: BorderRadius.circular(4.r),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Hjælpefunktion: generér BarChartGroupData til månedlig visning
  // ─────────────────────────────────────────────────────────────
  List<BarChartGroupData> _generateMonthlyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (var e in entries) {
      final int dom = e.timestamp.toLocal().day; // 1..31
      grouped.putIfAbsent(dom, () => []).add(e.ediLux);
    }

    final sortedDays = grouped.keys.toList()..sort();
    int idx = 0;
    return sortedDays.map((day) {
      final List<double> vals = grouped[day]!;
      final double avg = vals.reduce((a, b) => a + b) / vals.length;
      return BarChartGroupData(
        x: idx++,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0.0, 100.0),
            color: avg >= 75.0 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
            width: 12.w,
            borderRadius: BorderRadius.circular(4.r),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();
  }
}
