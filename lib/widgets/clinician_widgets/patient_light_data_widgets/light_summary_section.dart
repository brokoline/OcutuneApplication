// lib/widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Til at formatere DateTime → "HH:mm"

import '../../../../theme/colors.dart';
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

    // 1) Ugesammensætning (kun hvis du vil bruge weekMap til noget andet)
    final Map<String, double> weekMap = LightUtils.groupLuxByWeekdayName(data);

    // 2) FlSpot-liste til daglig graf (hvis LightDailyBarChart internt bruger den)
    final List<FlSpot> spots = data.map((e) {
      final double x = e.timestamp.hour + (e.timestamp.minute / 60.0);
      final double y = e.ediLux; // EDI ligger 0..1, multipliseres med 100 i grafen
      return FlSpot(x, (y * 100).clamp(0.0, 100.0));
    }).toList();

    // 3) Mini-bars til daglig graf (hvis LightDailyBarChart internt bruger dem)
    final List<BarChartGroupData> weeklyBars = _generateWeeklyBars(data);
    final List<BarChartGroupData> monthlyBars = _generateMonthlyBars(data);

    // 4) Generer anbefalinger via ChronotypeManager (ud fra rMEQ‐score)
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final String chronoLabel = chrono.getChronotypeLabel();
    final Map<String, DateTime> timeMap = chrono.getRecommendedTimes();
    final DateFormat fmt = DateFormat('HH:mm');

    final List<String> recs = [
      "Kronotype: $chronoLabel",
      "DLMO (Dim Light Melatonin Onset): ${fmt.format(timeMap['dlmo']!)}",
      "Sengetid (DLMO + 2 timer): ${fmt.format(timeMap['sleep_start']!)}",
      "Opvågning (DLMO + 10 timer): ${fmt.format(timeMap['wake_time']!)}",
      "Light‐boost start: ${fmt.format(timeMap['lightboost_start']!)}",
      "Light‐boost slut: ${fmt.format(timeMap['lightboost_end']!)}",
    ];

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
        LightSlideBarChart(rawData: data),
        SizedBox(height: 24.h),

        // ─────── 4) Seneste events liste ──────────────────────────
        LightLatestEventsList(lightData: data),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// Gruppen for “daglige minigrafer” – bruges internt i LightDailyBarChart
  List<BarChartGroupData> _generateWeeklyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (final e in entries) {
      final int wd = e.timestamp.weekday; // 1 = mandag … 7 = søndag
      final double scorePct = e.calculatedScore * 100.0;
      grouped.putIfAbsent(wd, () => []).add(scorePct);
    }

    return grouped.entries.map((entry) {
      final int weekday = entry.key;            // 1..7
      final List<double> allScores = entry.value;
      final double avg = allScores.reduce((a, b) => a + b) / allScores.length;
      return BarChartGroupData(
        x: weekday, // placér søjlen ved x = 1..7
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

  // ────────────────────────────────────────────────────────────────────────────
  /// Gruppér for “månedlige minigrafer” – bruges internt i LightDailyBarChart
  List<BarChartGroupData> _generateMonthlyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (final e in entries) {
      final int dom = e.timestamp.day; // 1..31
      final double scorePct = e.calculatedScore * 100.0;
      grouped.putIfAbsent(dom, () => []).add(scorePct);
    }

    final List<int> sortedKeys = grouped.keys.toList()..sort();
    int idx = 0;
    return sortedKeys.map((day) {
      final List<double> allScores = grouped[day]!;
      final double avg = allScores.reduce((a, b) => a + b) / allScores.length;
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
