// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

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
      // 2) FutureBuilder forventer nu List<DailyLightSummary>, ikke List<LightData>
      future: ApiService.fetchWeeklyLightData(patientId: patientId),
      builder: (context, snapshot) {
        // Loader‐tilstand
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // Fejl‐tilstand
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

        // Hent de 7 daglige aggregater
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

        // Sortér data (i princippet skal serveren allerede returnere mandag→søndag)
        weeklyData.sort((a, b) => a.day.compareTo(b.day));

        // Beregn procentsatser for hver dag (0=Man..6=Søn)
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

        // Byg de 7 stak‐søjler
        List<BarChartGroupData> barGroups = [];
        for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
          final double below = pctBelowList[dayIndex].clamp(0.0, 100.0);
          final double above = pctAboveList[dayIndex].clamp(0.0, 100.0);

          final summary = weeklyData[dayIndex];
          final bool hasData = summary.totalMeasurements > 0;

          if (!hasData) {
            // Hele søjlen grå, hvis ingen målinger
            barGroups.add(
              BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    color: Colors.grey.shade600,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            );
          } else {
            // Stak‐søjle: blå = pctBelow, orange = pctAbove
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
                        below + above, // = 100
                        const Color(0xFFFFAB00),
                      ),
                    ],
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: Colors.grey.withOpacity(0.15),
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

        return Card(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ugentlig lysmængde',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 12.h),
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
                            color: Colors.grey.withOpacity(0.3),
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
                              return SideTitleWidget(
                                meta: meta,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
