import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



class LightRecommendationsCard extends StatelessWidget {
  final List<String> recommendations;

  const LightRecommendationsCard({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Anbefalinger", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          ...recommendations.map((r) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.white70, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(child: Text(r, style: TextStyle(color: Colors.white, fontSize: 13.sp))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
