import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/colors.dart';


class LightRecommendationsCard extends StatelessWidget {
  final List<String> recommendations;

  const LightRecommendationsCard({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Anbefalinger", style: TextStyle(color: Colors.white, fontSize: 16.sp)),
            SizedBox(height: 12.h),
            ...recommendations.map((r) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white70, size: 16.sp),
                  SizedBox(width: 10.w),
                  Expanded(child: Text(r, style: TextStyle(color: Colors.white, fontSize: 13.sp))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
