import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            horizontal: 16.w,
            vertical: 20.h,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomerLightSummarySection(
                rmeqScore: rmeq,
                meqScore: meq,
                chronotype: chrono,
                recommendations: recommendations,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }
}
