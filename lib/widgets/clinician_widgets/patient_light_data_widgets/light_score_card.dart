import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/colors.dart';
import '../../../controller/chronotype_controller.dart';

class LightScoreCard extends StatelessWidget {
  final double score;
  final int totalScore;

  const LightScoreCard({
    super.key,
    required this.score,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).clamp(0, 100).toInt();

    final chrono = ChronotypeManager(totalScore);
    final meq = chrono.meqScore.toStringAsFixed(0);
    final chronotype = chrono.getChronotypeLabel();

    final baseColor = _getScoreColor(score);
    final chronoColor = _getChronotypeColor(chronotype);
    final donutColor = _blendColors(baseColor, chronoColor, 0.5);
    final glowColor = donutColor.withOpacity(0.4);

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
                        ShaderMask(
                          shaderCallback: (rect) {
                            return SweepGradient(
                              startAngle: 0.0,
                              endAngle: 3.14 * 2,
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
                _InfoTile(label: "Chronotype", value: chronotype),
                _InfoTile(label: "MEQ", value: meq),
                _InfoTile(label: "rMEQ", value: totalScore.toString()),
              ],
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

  Color _getChronotypeColor(String type) {
    switch (type) {
      case 'definitely_morning':
        return Colors.blueAccent;
      case 'moderately_morning':
        return Colors.lightBlue;
      case 'neither':
        return Colors.grey;
      case 'moderately_evening':
        return Colors.orangeAccent;
      case 'definitely_evening':
        return Colors.deepOrange;
      default:
        return Colors.white60;
    }
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
