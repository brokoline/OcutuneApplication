// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LightWeeklyBarChart extends StatelessWidget {
  /// Ugedags-værdier (nøgler = "Man","Tir",…”Søn”; værdier = procent 0..100).
  final Map<String, double> luxPerDay;

  const LightWeeklyBarChart({
    Key? key,
    required this.luxPerDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Kendte ugedage i fast rækkefølge
    const List<String> weekdayKeys = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    // 2) Hent procentværdier for hver dag. Hvis en dag mangler, sæt 0.0
    final List<double> values = weekdayKeys.map((k) => luxPerDay[k] ?? 0.0).toList();

    // 3) Farver: Orange/gul for "god dag" (>=50%), lys blå for "dårlig dag" (<50%)
    //    Hvis du vil ændre tærsklen, justér `threshold`-variablen.
    const double threshold = 50.0;
    const Color goodColor = Color(0xFFFFAB00);  // Orange/gul
    const Color badColor  = Color(0xFF5DADE2);  // Lys blå

    return Card(
      color: const Color(0xFF2A2A2A), // eksempel på baggrundsfarve, kan udskiftes
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ugentlig lysmængde",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  backgroundColor: const Color(0xFF2A2A2A),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, horizontalInterval: 20, getDrawingHorizontalLine: (y) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          final String label = (idx >= 0 && idx < weekdayKeys.length)
                              ? weekdayKeys[idx]
                              : '';
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            "${value.toInt()}%",
                            style: TextStyle(fontSize: 10.sp, color: Colors.white54),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(weekdayKeys.length, (int i) {
                    final double yVal = values[i].clamp(0.0, 100.0);

                    // Hvis yVal >= threshold → orange/gul (goodColor), ellers blå (badColor)
                    final Color barColor = (yVal >= threshold) ? goodColor : badColor;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: yVal,
                          color: barColor,
                          width: 14.w,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
