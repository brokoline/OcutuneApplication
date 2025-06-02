// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../services/services/api_services.dart';

class LightWeeklyBarChart extends StatelessWidget {
  final String patientId;

  const LightWeeklyBarChart({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LightData>>(
      future: ApiService.fetchWeeklyLightData(patientId: patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
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
        } else {
          final rawData = snapshot.data ?? [];
          if (rawData.isEmpty) {
            return SizedBox(
              height: 200.h,
              child: Center(
                child: Text(
                  'Ingen lysmålinger i denne uge (UTC).',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 1) Beregn ugens start/slut i UTC (valgfrit, hvis API allerede filtrerer)
          final nowUtc = DateTime.now().toUtc();
          final currentWeekday = nowUtc.weekday; // 1=mandag … 7=søndag
          final startOfWeek = DateTime.utc(
            nowUtc.year,
            nowUtc.month,
            nowUtc.day,
          ).subtract(Duration(days: currentWeekday - 3));
          final endOfWeek = startOfWeek.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          );

          // 2) Filtrer lokalt igen (hvis I vil dobbelttjekke):
          final thisWeekData = rawData.where((e) {
            final tsUtc = e.capturedAt.toUtc();
            return tsUtc.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
                tsUtc.isBefore(endOfWeek.add(const Duration(milliseconds: 1)));
          }).toList();

          // 3) GroupByWeekday: giver Map<int,double> med 0=mand…, 6=søn
          final Map<int, double> weekdayMap = LightUtils.groupByWeekday(thisWeekData);

          // 4) Tæl datapunkter pr dag (1..7)
          final countByWeekday = <int, int>{ for (int wd = 1; wd <= 7; wd++) wd: 0 };
          for (final e in thisWeekData) {
            final int wd = e.capturedAt.toUtc().weekday; // 1..7
            countByWeekday[wd] = countByWeekday[wd]! + 1;
          }

          // 5) Definér farver
          const Color goodColor = Color(0xFFFFAB00);
          const Color badColor = Color(0xFF5DADE2);
          final Color neutralColor = Colors.grey.shade600;

          // 6) Lav en List<BarChartGroupData> med stacked rods:
          final List<BarChartGroupData> barGroups = List.generate(7, (idx) {
            final int weekdayKey = idx + 1; // 1=mandag..7=søndag
            final double dailyAvg = (weekdayMap[idx] ?? 0.0).clamp(0.0, 100.0);

            if (countByWeekday[weekdayKey]! == 0) {
              // Ingen data denne dag → hele baren grå
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    color: neutralColor,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                    backDrawRodData: BackgroundBarChartRodData(show: false, toY: 0),
                  ),
                ],
              );
            }

            // Ellers: under‐delen = blå (0 → 100−dailyAvg), over‐delen = orange (100−dailyAvg → 100)
            final double underPortion = 100.0 - dailyAvg;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: 100.0,
                  width: 14.w,
                  borderRadius: BorderRadius.circular(4.r),
                  rodStackItems: [
                    BarChartRodStackItem(0, underPortion, badColor),
                    BarChartRodStackItem(underPortion, 100.0, goodColor),
                  ],
                  backDrawRodData: BackgroundBarChartRodData(show: false, toY: 0),
                ),
              ],
            );
          });

          // 7) Tegn selve grafen (med danske ugedagsforkortelser)
          const List<String> weekdayLabels = [
            'Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'
          ];
          return Card(
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ugentlig lysmængde',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 180.h,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (y) => FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) => Text(
                                "${value.toInt()}%",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10.sp,
                                ),
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
                        barGroups: barGroups,
                        groupsSpace: 6.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
