import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/colors.dart';

class LightScoreCard extends StatelessWidget {
  final double score;

  const LightScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).clamp(0, 100).toInt();
    final color = score >= 0.7
        ? Colors.green
        : score >= 0.4
        ? Colors.orange
        : Colors.red;

    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            Text("Lys-score", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            SizedBox(
              height: 100.w,
              width: 100.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score,
                    strokeWidth: 6,
                    color: color,
                    backgroundColor: Colors.white12,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$percent%', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      Text(
                        score >= 0.7 ? "God" : score >= 0.4 ? "Middel" : "Lav",
                        style: TextStyle(color: color, fontSize: 12.sp),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
