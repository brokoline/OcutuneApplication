import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../models/light_data_model.dart';
import '../../../../utils/light_utils.dart';

import '../patient_light_data_widgets/light_recommendations_card.dart';
import 'light_score_card.dart';
import 'light_daily_line_chart.dart';
import 'light_weekly_bar_chart.dart';
import 'light_latest_events_list.dart';

class LightSummarySection extends StatelessWidget {
  final List<LightData> data;
  final int rmeqScore;
  final int? meqScore; // nu valgfri

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

    final processor = LightDataProcessing(rMEQ: rmeqScore);

    final weeklyBars    = _generateWeeklyBars(data);
    final monthlyBars   = _generateMonthlyBars(data);
    final weekMap       = processor.groupLuxByWeekdayName(data);
    final recs          = processor.generateAdvancedRecommendations(data: data, rMEQ: rmeqScore);
    final spots         = data.map((e) {
      final x = e.timestamp.hour.toDouble() + e.timestamp.minute.toDouble() / 60;
      return FlSpot(x, e.ediLux);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LightRecommendationsCard(recommendations: recs),
        SizedBox(height: 16.h),
        LightScoreCard(
          rmeqScore: rmeqScore,
          meqScore: meqScore ?? 0, // vis 0 hvis ikke sat
        ),
        SizedBox(height: 24.h),
        LightDailyLineChart(
          lightData: spots,
          totalScore: rmeqScore,
          weeklyBars: weeklyBars,
          monthlyBars: monthlyBars,
        ),
        SizedBox(height: 24.h),
        LightWeeklyBarChart(luxPerDay: weekMap),
        SizedBox(height: 24.h),
        LightLatestEventsList(lightData: data),
      ],
    );
  }

  List<BarChartGroupData> _generateWeeklyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (var e in entries) {
      grouped.putIfAbsent(e.timestamp.weekday, () => []).add(e.calculatedScore * 100);
    }
    return grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0, 100),
            color: avg >= 75 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _generateMonthlyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (var e in entries) {
      grouped.putIfAbsent(e.timestamp.day, () => []).add(e.calculatedScore * 100);
    }
    int index = 0;
    return grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0, 100),
            color: avg >= 75 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
          ),
        ],
      );
    }).toList();
  }
}
