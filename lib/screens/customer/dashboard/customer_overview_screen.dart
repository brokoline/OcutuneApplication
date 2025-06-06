// lib/screens/customer/dashboard/overview_screen.dart

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../widgets/customer_widgets/light_widgets/customer_light_summary_section.dart';
import '../../../models/customer_model.dart';

class CustomerOverviewScreen extends StatelessWidget {
  final Customer profile;
  final List<String> recommendations;

  const CustomerOverviewScreen({
    Key? key,
    required this.profile,
    required this.recommendations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int rmeq       = profile.rmeqScore;
    final int meq        = profile.meqScore ?? 0;
    final String chrono  = profile.chronotype.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomerLightSummarySection(
            rmeqScore:       rmeq,
            meqScore:        meq,
            chronotype:      chrono,
            recommendations: recommendations,
          ),
          const SizedBox(height: 40),
          // Tilføj gerne mere indhold her efter behov
        ],
      ),
    );
  }
}
