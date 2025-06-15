import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
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
    // 🛠️ Her laves debug-bypass
    final String patientIdForLightData = kDebugMode ? 'P3' : patientId;

    return FutureBuilder<List<DailyLightSummary>>(
      future: ApiService.fetchWeeklyLightData(patientId: patientIdForLightData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        final List<double> pctAboveList = List.generate(7, (i) {
          final summary = weeklyData[i];
          return summary.totalMeasurements == 0
              ? 0.0
              : (summary.countHighLight / summary.totalMeasurements) * 100.0;
        });

        final List<double> pctBelowList = List.generate(7, (i) {
          return 100.0 - pctAboveList[i];
        });

        List<BarChartGroupData> barGroups = List.generate(7, (i) {
          final below = pctBelowList[i].clamp(0.0, 100.0);
          final above = pctAboveList[i].clamp(0.0, 100.0);
          final summary = weeklyData[i];
          final hasData = summary.totalMeasurements > 0;

          return BarChartGroupData(
            x: i,
            barRods: [
              hasData
                  ? BarChartRodData(
                toY: 100.0,
                width: 14.w,
                borderRadius: BorderRadius.circular(4.r),
                rodStackItems: [
                  BarChartRodStackItem(0, below, const Color(0xFF5DADE2)),
                  BarChartRodStackItem(below, below + above, const Color(0xFFFFAB00)),
                ],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: const Color(0xFF444444),
                ),
              )
                  : BarChartRodData(
                toY: 100.0,
                color: const Color(0xFF4A4A4A),
                width: 14.w,
                borderRadius: BorderRadius.circular(4.r),
              )
            ],
          );
        });

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
                    getDrawingHorizontalLine: (y) => FlLine(
                      color: Colors.white24,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(
                          "${value.toInt()}%",
                          style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                        ),
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
                              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
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
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: const Color(0xFFFFAB00), size: 18.sp),
                      SizedBox(width: 10.w),
                      Text(
                        "Tidspunkt med optimal lyseksponering",
                        style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: const Color(0xFF5DADE2), size: 18.sp),
                      SizedBox(width: 10.w),
                      Text(
                        "Tidspunkt med uoptimal lyseksponering",
                        style: TextStyle(color: Colors.white70, fontSize: 14.sp),
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
