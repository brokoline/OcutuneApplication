// lib/widgets/customer_widgets/customer_light_summary_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'customer_slide_bar_chart.dart';

/// En samlet “Customer”‐summary‐sektion, der viser:
///   1) Lys‐anbefalinger
///   2) Lys‐score (rMEQ, MEQ og kronotype)
///   3) Lys‐eksponering som swipebar (Dag / Uge / Måned)
///
/// Forudsætter, at du sender ind:
///   - rmeqScore (int)
///   - meqScore (int)
///   - chronotype (String)
///   - recommendations (List<String>)
class CustomerLightSummarySection extends StatelessWidget {
  /// rMEQ (int) fra kundens profil
  final int rmeqScore;

  /// MEQ (int) fra kundens profil
  final int meqScore;

  /// Kronotype‐label fra kundens profil
  final String chronotype;

  /// Liste af lys‐anbefalinger til kunden
  final List<String> recommendations;

  const CustomerLightSummarySection({
    Key? key,
    required this.rmeqScore,
    required this.meqScore,
    required this.chronotype,
    required this.recommendations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Lys‐eksponering: Dag / Uge / Måned swipebar
        const Text(
          'Oversigt over din lyseksponering',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
