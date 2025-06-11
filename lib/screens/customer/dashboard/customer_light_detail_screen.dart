
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/customer_model.dart';
import '../../../theme/colors.dart';
import '../../../widgets/customer_widgets/light_widgets/customer_light_summary_section.dart';

class CustomerLightDetailScreen extends StatelessWidget {
  final Customer profile;

  const CustomerLightDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final int rmeq = profile.rmeqScore;
    final int meq = profile.meqScore ?? 0;
    final String chrono = profile.chronotype.name;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fyldtekst
              Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Text(
                  'Her vil du fremover kunne se flere dybdegående lysgrafer, '
                      'bl.a. omkring hvilke slags lys du har været eksponeret for (dagslys, LED, fluorescens osv.) '
                      'og andre spændende indsigter!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              // Summary-section med RIGTIGE data
              CustomerLightSummarySection(
                rmeqScore: rmeq,
                meqScore: meq,
                chronotype: chrono,
                recommendations: const [], // eller de anbefalinger du ønsker
              ),
            ],
          ),
        ),
      ),
    );
  }
}
