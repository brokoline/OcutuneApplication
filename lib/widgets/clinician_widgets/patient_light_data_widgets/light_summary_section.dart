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

  const LightSummarySection({
    super.key,
    required this.data,
    required this.rmeqScore,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text('Ingen lysdata registreret endnu',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
      );
    }

    final processor = LightDataProcessing(rMEQ: rmeqScore);

    final score = LightData.averageScore(data);
    final weeklyBars = _generateWeeklyBars(data);
    final monthlyBars = _generateMonthlyBars(data);
    final weekMap = processor.groupLuxByWeekdayName(data);
    final recs = processor.generateAdvancedRecommendations(data: data, rMEQ: rmeqScore);

    final List<FlSpot> spots = data.map((e) => FlSpot(
      e.timestamp.hour.toDouble() + (e.timestamp.minute.toDouble() / 60),
      e.ediLux,
    )).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LightRecommendationsCard(recommendations: recs),
        SizedBox(height: 8.h),
        LightScoreCard(
          score: score,
          totalScore: rmeqScore,
        ),
        SizedBox(height: 8.h),
        LightDailyLineChart(
          lightData: spots,
          totalScore: rmeqScore,
          weeklyBars: weeklyBars,
          monthlyBars: monthlyBars,
        ),
        SizedBox(height: 8.h),
        LightWeeklyBarChart(
          luxPerDay: weekMap,
        ),
        SizedBox(height: 8.h),
        LightLatestEventsList(lightData: data),
      ],
    );
  }

  List<BarChartGroupData> _generateWeeklyBars(List<LightData> entries) {
    final Map<int, List<double>> grouped = {};
    for (var entry in entries) {
      final weekday = entry.timestamp.weekday;
      grouped.putIfAbsent(weekday, () => []).add(entry.calculatedScore * 100);
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
    final Map<String, List<double>> grouped = {};
    for (var entry in entries) {
      final dayKey = entry.timestamp.day.toString();
      grouped.putIfAbsent(dayKey, () => []).add(entry.calculatedScore * 100);
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
