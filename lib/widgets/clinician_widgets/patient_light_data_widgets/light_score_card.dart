import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/theme/colors.dart';
import '../../../controller/chronotype_controller.dart';

class LightScoreCard extends StatelessWidget {
  /// rMEQ: kort version (5 spørgsmål)
  final int rmeqScore;

  /// MEQ: lang version (19 spørgsmål)
  final int meqScore;

  const LightScoreCard({
    Key? key,
    required this.rmeqScore,
    required this.meqScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ratio = (rmeqScore / 25).clamp(0.0, 1.0);
    final percent = (ratio * 100).toInt();

    final chronoLabel = ChronotypeManager(rmeqScore).getChronotypeLabel();
    final baseColor   = _getScoreColor(ratio);
    final chronoColor = _getChronotypeColor(chronoLabel);
    final donutColor  = Color.lerp(baseColor, chronoColor, 0.5)!;
    final glowColor   = donutColor.withOpacity(0.4);

    return Card(
      color: generalBox,
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
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (ctx, value, _) {
                  return SizedBox(
                    height: 160.w,
                    width: 160.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // glow
                        Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: glowColor, blurRadius: 25.w, spreadRadius: 8.w)
                            ],
                          ),
                        ),
                        // donut
                        ShaderMask(
                          shaderCallback: (rect) {
                            return SweepGradient(
                              startAngle: 0,
                              endAngle: 2 * 3.1415,
                              stops: [value, value],
                              center: Alignment.center,
                              colors: [donutColor, Colors.white.withOpacity(0.08)],
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
                        // labels
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
                              _getScoreLabel(ratio),
                              style: TextStyle(
                                color: donutColor,
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
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoTile(label: "Kronotype", value: chronoLabel),
                _InfoTile(
                  label: "MEQ",
                  value: meqScore > 0 ? meqScore.toString() : "–", // tom hvis 0
                ),
                _InfoTile(label: "rMEQ", value: rmeqScore.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double ratio) {
    if (ratio >= 0.7) return Color.lerp(Colors.greenAccent, Colors.green, 0.6)!;
    if (ratio >= 0.4) return Color.lerp(Colors.amber, Colors.orange, 0.5)!;
    return Color.lerp(Colors.redAccent, Colors.red, 0.5)!;
  }

  Color _getChronotypeColor(String type) {
    switch (type) {
      case 'definitely_morning':   return Colors.blueAccent;
      case 'moderately_morning':   return Colors.lightBlue;
      case 'neither':              return Colors.grey;
      case 'moderately_evening':   return Colors.orangeAccent;
      case 'definitely_evening':   return Colors.deepOrange;
      default:                     return Colors.white60;
    }
  }

  String _getScoreLabel(double ratio) {
    if (ratio >= 0.7) return "Fremragende";
    if (ratio >= 0.4) return "Moderat";
    return "Forbedring";
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
        SizedBox(height: 4.h),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
