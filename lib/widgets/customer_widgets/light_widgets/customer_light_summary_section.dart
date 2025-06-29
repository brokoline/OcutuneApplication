import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'customer_slide_bar_chart.dart';

class CustomerLightSummarySection extends StatelessWidget {
  final int rmeqScore;
  final int meqScore;
  final String chronotype;
  final List<String> recommendations;

  const CustomerLightSummarySection({
    super.key,
    required this.rmeqScore,
    required this.meqScore,
    required this.chronotype,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Din lyseksponering over tid',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CustomerLightSlideBarChart(
          rmeqScore: rmeqScore,
          chronotype: chronotype,
        ),
      ],
    );
  }
}
