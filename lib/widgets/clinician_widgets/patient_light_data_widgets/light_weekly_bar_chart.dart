// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/colors.dart';

class LightWeeklyBarChart extends StatelessWidget {
  /// Vi modtager en map “dagLabel → procent”, f.eks. { 'Man': 20.5, 'Tir': 45.0, … }
  final Map<String, double> luxPerDay;

  const LightWeeklyBarChart({
    Key? key,
    required this.luxPerDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Definér en fast, korrekt rækkefølge af ugedag‐labels:
    const List<String> weekdayKeys = [
      'Man',
      'Tir',
      'Ons',
      'Tor',
      'Fre',
      'Lør',
      'Søn',
    ];

    // 2) Byg en liste af værdier i nøjagtig samme rækkefølge:
    final List<double> values = weekdayKeys
        .map((label) => (luxPerDay[label] ?? 0.0).clamp(0.0, 100.0))
        .toList();

    return Card(
      color: generalBox,
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
                  backgroundColor: generalBox,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, horizontalInterval: 20),

                  // ---------------- TITLER (NY API v1.x) ----------------
                  titlesData: FlTitlesData(
                    show: true,

                    // BUND (X‐aksen) TITLER
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,       // Én søjle = én titel
                        reservedSize: 32,  // Plads til “Lør” osv.
                        getTitlesWidget:
                            (double value, TitleMeta meta) { // Husk begge parametre
                          final int idx = value.toInt();
                          // Tjek at idx er inden for 0..6
                          final String label =
                          (idx >= 0 && idx < weekdayKeys.length)
                              ? weekdayKeys[idx]
                              : '';
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // VENSTRE (Y‐aksen) TITLER
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            "${value.toInt()}%",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white54,
                            ),
                          );
                        },
                      ),
                    ),

                    // SKJUL top‐ og right‐titler
                    topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  // ---------------- BAR‐DATA ----------------
                  barGroups: List.generate(weekdayKeys.length, (int i) {
                    final double yVal = values[i];
                    final Color barColor =
                    (yVal >= 75.0) ? const Color(0xFF00C853) : const Color(0xFFFFAB00);
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
