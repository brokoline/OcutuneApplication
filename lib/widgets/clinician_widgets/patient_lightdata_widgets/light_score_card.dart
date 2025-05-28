import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/colors.dart'; // Sørg for at generalBox er defineret her

class LightScoreCard extends StatelessWidget {
  final double score;

  const LightScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).clamp(0, 100).toInt();
    final color = _getScoreColor(score);
    final glowColor = color.withOpacity(0.4);

    return Card(
      color: generalBox, // Brug din egen baggrundsfarve her
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 8,
      shadowColor: glowColor,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seneste målinger",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return SizedBox(
                    height: 160.w,
                    width: 160.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glowing shadow
                        Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: glowColor,
                                blurRadius: 25.w,
                                spreadRadius: 8.w,
                              ),
                            ],
                          ),
                        ),
                        // Gradient ring
                        ShaderMask(
                          shaderCallback: (rect) {
                            return SweepGradient(
                              startAngle: 0.0,
                              endAngle: 3.14 * 2,
                              stops: [value, value],
                              center: Alignment.center,
                              colors: [color, Colors.white.withOpacity(0.08)],
                            ).createShader(rect);
                          },
                          child: Container(
                            width: 140.w,
                            height: 140.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Text in the middle
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$percent%",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              _getScoreLabel(score),
                              style: TextStyle(
                                color: color,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Døgnscore",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return _blendColors(Colors.greenAccent, Colors.green, 0.6);
    if (score >= 0.4) return _blendColors(Colors.amber, Colors.orange, 0.5);
    return _blendColors(Colors.redAccent, Colors.red, 0.5);
  }

  String _getScoreLabel(double score) {
    if (score >= 0.7) return "Fremragende";
    if (score >= 0.4) return "Moderat";
    return "Forbedring";
  }

  Color _blendColors(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio)!;
  }
}
