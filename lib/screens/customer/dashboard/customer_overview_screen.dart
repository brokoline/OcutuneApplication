import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/light_widgets/customer_light_daily_chart.dart';
import '../../../widgets/customer_widgets/light_widgets/customer_light_recomandations_card.dart';
import '../../../widgets/customer_widgets/light_widgets/customer_light_summary_section.dart';
import '../../../models/customer_model.dart';

class CustomerOverviewScreen extends StatelessWidget {
  final Customer profile;
  final List<String> recommendations;

  const CustomerOverviewScreen({
    super.key,
    required this.profile,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) {
        final int rmeq = profile.rmeqScore;
        final int meq = profile.meqScore ?? 0;
        final String chrono = profile.chronotype.name;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomerLightRecommendationsCard(
                recommendations: recommendations,
              ),
              SizedBox(height: 10.h), // Mindre afstand!
              CustomerLightDailyBarChart(
                rmeqScore: rmeq,
              ),
              // Fjern evt. sidste spacing helt
              // SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}
