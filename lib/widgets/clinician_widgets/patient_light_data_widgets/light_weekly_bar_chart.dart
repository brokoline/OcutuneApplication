// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';

class LightWeeklyBarChart extends StatelessWidget {
  /// Rå liste af lysmålinger (én LightData pr. timestamp), kan indeholde data fra flere måneder.
  final List<LightData> rawData;

  const LightWeeklyBarChart({
    super.key,
    required this.rawData,
  });

  @override
  Widget build(BuildContext context) {
    // ────────────────────────────────────────────────────────────
    // 1) Find start og slut på "denne uge" (mandag kl. 00:00:00 til søndag kl. 23:59:59).
    final DateTime now = DateTime.now();

    // Beregn mandag i denne uge (ugebegyndelse)
    final int currentWeekday = now.weekday; // 1=mandag, 7=søndag
    final DateTime startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentWeekday - 1));

    // Beregn søndag i denne uge (ugeafslutning)
    final DateTime endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    // ────────────────────────────────────────────────────────────
    // 2) Filtrér rawData til kun at indeholde målinger i dette interval:
    final List<LightData> thisWeekData = rawData.where((e) {
      final DateTime ts = e.timestamp;
      return (ts.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
          ts.isBefore(endOfWeek.add(const Duration(milliseconds: 1))));
    }).toList();

    // ────────────────────────────────────────────────────────────
    // 3) Gruppér per ugedag (1=mandag … 7=søndag) og beregn gennemsnitlig % for hver dag.
    //    LightUtils.groupByWeekday returnerer et Map<int,double> med nøgle 1..7.
    final Map<int, double> weekdayMap = LightUtils.groupByWeekday(thisWeekData);

    // ────────────────────────────────────────────────────────────
    // 4) Lav en fast rækkefølge af danske ugedagsforkortelser:
    const List<String> weekdayLabels = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    // 5) Udtræk procent‐værdier: hvis en dag mangler (ikke i map), sæt 0.0
    final List<double> values = List.generate(7, (index) {
      final int weekdayNumber = index + 1; // 1..7
      return (weekdayMap[weekdayNumber] ?? 0.0).clamp(0.0, 100.0);
    });

    // ────────────────────────────────────────────────────────────
    // 6) Tærskel og farver: ≥50 % = "optimum" (orange/gul), ellers "under" (lys blå).
    const double threshold = 50.0;
    const Color goodColor = Color(0xFFFFAB00); // Orange/gul
    const Color badColor  = Color(0xFF5DADE2); // Lys blå

    // ────────────────────────────────────────────────────────────
    // 7) Byg én BarChartGroupData pr. dag i den rækkefølge [Man(0), Tir(1), Ons(2), … Søn(6)].
    final List<BarChartGroupData> barGroups = List.generate(7, (int idx) {
      final double yVal = values[idx];
      final Color barColor = (yVal >= threshold) ? goodColor : badColor;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: yVal,
            color: barColor,
            width: 14.w,
            borderRadius: BorderRadius.circular(4.r),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100, // bagvedliggende “100 %” som svag grå
              color: Colors.grey.withOpacity(0.15),
            ),
          ),
        ],
      );
    });

    // ────────────────────────────────────────────────────────────
    // 8) Returnér BarChart‐widget
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // – Titel
            Text(
              'Ugentlig lysmængde',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // – Graf i fast højde
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,

                  // Grid, kun vandrette linjer
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (double y) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),

                  // Fjern kantlinjer
                  borderData: FlBorderData(show: false),

                  // Titler på akserne
                  titlesData: FlTitlesData(
                    show: true,

                    // VENSTRE (Y‐aksen): “0%, 20%, 40%, …”
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                            ),
                          );
                        },
                      ),
                    ),

                    // BUND (X‐aksen): én etiket pr. dag i rækkefølge Man..Søn
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1, // siden vi genererer 7 grupper med x=0..6
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx < 0 || idx >= weekdayLabels.length) {
                            return const SizedBox.shrink();
                          }
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

                  // Bar‐grupperne
                  barGroups: barGroups,

                  // Spacing mellem bar‐grupperne
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
