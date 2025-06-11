import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/daily_light_summary_model.dart';
import '../../../services/services/api_services.dart';

class LightWeeklyBarChart extends StatelessWidget {
  final String patientId;

  const LightWeeklyBarChart({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyLightSummary>>(
      future: ApiService.fetchWeeklyLightData(patientId: patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loader uden baggrund
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: Text(
                'Fejl ved hentning af ugentlige data: ${snapshot.error}',
                style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final weeklyData = snapshot.data ?? [];
        if (weeklyData.isEmpty) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: Text(
                'Ingen lysmålinger i denne uge.',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        weeklyData.sort((a, b) => a.day.compareTo(b.day));

        final List<double> pctAboveList = List<double>.generate(7, (i) {
          final summary = weeklyData[i];
          if (summary.totalMeasurements == 0) return 0.0;
          return (summary.countHighLight / summary.totalMeasurements) * 100.0;
        });
        final List<double> pctBelowList = List<double>.generate(7, (i) {
          final summary = weeklyData[i];
          if (summary.totalMeasurements == 0) return 0.0;
          return 100.0 - pctAboveList[i];
        });

        List<BarChartGroupData> barGroups = [];
        for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
          final double below = pctBelowList[dayIndex].clamp(0.0, 100.0);
          final double above = pctAboveList[dayIndex].clamp(0.0, 100.0);

          final summary = weeklyData[dayIndex];
          final bool hasData = summary.totalMeasurements > 0;

          if (!hasData) {
            barGroups.add(
              BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    color: const Color(0xFF4A4A4A), // Mørkere grå
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            );
          } else {
            barGroups.add(
              BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                    rodStackItems: [
                      BarChartRodStackItem(
                        0,
                        below,
                        const Color(0xFF5DADE2),
                      ),
                      BarChartRodStackItem(
                        below,
                        below + above,
                        const Color(0xFFFFAB00),
                      ),
                    ],
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: const Color(0xFF444444), // Mørkere grå
                    ),
                  ),
                ],
              ),
            );
          }
        }

        const List<String> weekdayLabels = [
          'Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                'Ugentlig lysmængde',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  backgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (y) {
                      return FlLine(
                        color: Colors.white24,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${value.toInt()}%",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 6) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Text(
                              weekdayLabels[idx],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 8.w,
                  barGroups: barGroups,
                ),
              ),
            ),
            SizedBox(height: 22.h),
            // Legend samme stil som daily
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: const Color(0xFFFFAB00), size: 16.sp),
                      SizedBox(height: 14.h),
                      Icon(Icons.circle, color: const Color(0xFF5DADE2), size: 16.sp),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Tidspunkt med optimal lyseksponering",
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        "Tidspunkt med uoptimal lyseksponering",
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
