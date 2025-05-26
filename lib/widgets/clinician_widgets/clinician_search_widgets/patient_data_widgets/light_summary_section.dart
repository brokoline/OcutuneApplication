import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../models/light_data_model.dart';
import '../../../../utils/light_utils.dart';

import 'light_score_card.dart';
import 'light_daily_line_chart.dart';
import 'light_weekly_bar_chart.dart';
import 'light_latest_events_list.dart';
import 'light_recommendations_card.dart';

class LightSummarySection extends StatelessWidget {
  final List<LightData> data;

  const LightSummarySection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text('Ingen lysdata registreret endnu',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
      );
    }

    final score = data.map((d) => d.exposureScore).reduce((a, b) => a + b) / data.length;
    final weekMap = groupLuxByDay(data);
    final recs = generateRecommendations(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LightRecommendationsCard(recommendations: recs),
        SizedBox(height: 8.h),
        LightScoreCard(score: score),
        SizedBox(height: 8.h),
        LightDailyLineChart(lightData: data),
        SizedBox(height: 8.h),
        LightWeeklyBarChart(luxPerDay: weekMap),
        SizedBox(height: 8.h),
        LightLatestEventsList(lightData: data),
      ],
    );
  }
}
