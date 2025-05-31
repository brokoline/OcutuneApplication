// lib/widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../theme/colors.dart';
import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../../models/light_data_model.dart';
import 'light_daily_line_chart.dart';
import 'light_latest_events_list.dart';
import 'light_recommendations_card.dart';
import 'light_score_card.dart';
import 'light_weekly_bar_chart.dart';

class LightSummarySection extends StatelessWidget {
  const LightSummarySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientDetailViewModel>();
    final List<LightData> data = vm.rawLightData;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Anbefalinger (Chronotype + ML)
        if (vm.processedLightData != null || vm.error != null || vm.isProcessing) ...[
          const LightRecommendationsCard(),
          SizedBox(height: 16.h),
        ],

        // Score‐kort: rMEQ + MEQ‐score
        const LightScoreCard(),
        SizedBox(height: 24.h),

        // Daglig linjegraf (EDI % over døgnet)
        const LightDailyLineChart(),
        SizedBox(height: 24.h),

        // Ugentlig søjle‐diagram
        const LightWeeklyBarChart(),
        SizedBox(height: 24.h),

        // "Seneste målinger"
        const LightLatestEventsList(),
      ],
    );
  }
}