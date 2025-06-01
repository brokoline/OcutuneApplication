// lib/widgets/clinician_widgets/patient_light_data_widgets/light_monthly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/colors.dart';
import '../../../utils/light_utils.dart';
import '../../../../models/light_data_model.dart';

class LightMonthlyBarChart extends StatelessWidget {
  /// Rå liste af LightData (én instans pr. timestamp)
  final List<LightData> rawData;

  const LightMonthlyBarChart({
    Key? key,
    required this.rawData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Hent mappet {dag_i_måneden: procent} via LightUtils.static‐metode
    final Map<int, double> domMap = LightUtils.groupByDayOfMonth(rawData);
    final List<int> sortedDays = domMap.keys.toList()..sort();

    // 2) Byg en liste af BarChartGroupData ud fra sortedDays
    final List<BarChartGroupData> groups = [];
    for (int idx = 0; idx < sortedDays.length; idx++) {
      final int day = sortedDays[idx];
      final double yVal = domMap[day]!.clamp(0.0, 100.0);
      final Color barColor = (yVal >= 75.0)
          ? const Color(0xFF00C853)
          : const Color(0xFFFFAB00);

      groups.add(
        BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: yVal,
              color: barColor,
              width: 16.w,
              borderRadius: BorderRadius.circular(4.r),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.withOpacity(0.15),
              ),
            ),
          ],
          barsSpace: 4.w,
        ),
      );
    }

    return Card(
      color: generalBox, // Din egen farve fra theme/colors.dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Månedlig lysmængde",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 200.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  alignment: BarChartAlignment.spaceBetween,
                  backgroundColor: generalBox,
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

                  // ---------------------- TITLER ----------------------
                  titlesData: FlTitlesData(
                    // BUND (X‐aksen) TITLER
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1, // Én titel per “søjle”
                        getTitlesWidget: (double val, TitleMeta meta) {
                          final int idx = val.toInt();
                          if (idx >= 0 && idx < sortedDays.length) {
                            return SideTitleWidget(
                              // Korrekt brug af meta‐parameter (v1.0+)
                              meta: meta,
                              child: Text(
                                sortedDays[idx].toString(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    // VENSTRE (Y‐aksen) TITLER
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20, // 0%, 20%, 40%, … 100%
                        reservedSize: 32, // Plads til “20%”‐teksten
                        getTitlesWidget: (double val, TitleMeta meta) {
                          return Text(
                            "${val.toInt()}%",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                            ),
                          );
                        },
                      ),
                    ),
                    // Skjul top og højre titler:
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  // -------------------- BAR‐DATA -----------------------
                  barGroups: groups,
                  groupsSpace: 4.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
