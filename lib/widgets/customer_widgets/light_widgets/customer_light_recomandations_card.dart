// lib/widgets/customer_widgets/customer_light_recommendations_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerLightRecommendationsCard extends StatelessWidget {
  final List<String> recommendations;

  const CustomerLightRecommendationsCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'Ingen anbefalinger tilgængelige',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
      child: Container(
        // Fjern color: generalBox, så den er transparent
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Anbefalinger",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ...recommendations.map((r) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white70,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
