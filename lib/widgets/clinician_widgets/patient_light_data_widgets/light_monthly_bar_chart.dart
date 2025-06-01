// lib/widgets/clinician_widgets/patient_light_data_widgets/light_monthly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/colors.dart';
import '../../../utils/light_utils.dart';
import '../../../../models/light_data_model.dart';
import '../../../controller/chronotype_controller.dart';

class LightMonthlyBarChart extends StatelessWidget {
  /// Rå liste af lysmålinger (én LightData per timestamp).
  final List<LightData> rawData;

  /// rMEQ‐score (bruges til at beregne DLMO og boost‐interval).
  final int rmeqScore;

  const LightMonthlyBarChart({
    Key? key,
    required this.rawData,
    required this.rmeqScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ──────────────────────────────────────────────────────────
    // 1) Gruppér per dag‐i‐måneden → gennemsnitlig lysprocent (0..100)
    final Map<int, double> domMap = LightUtils.groupByDayOfMonth(rawData);
    final List<int> sortedDays = domMap.keys.toList()..sort();

    // ──────────────────────────────────────────────────────────
    // 2) Brug ChronotypeManager til at hente:
    //    • DLMO (DateTime) → DLMO‐dag i måneden
    //    • lightboostStartHour / lightboostEndHour (timer fra midnat)
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final Map<String, DateTime> timeMap = chrono.getRecommendedTimes();
    final DateTime dlmoTime = timeMap['dlmo']!; // Her antager vi, at 'dlmo' altid findes
    final int recommendedDayOfMonth = dlmoTime.day;
    final double startBoostHour = chrono.lightboostStartHour;
    final double endBoostHour   = chrono.lightboostEndHour;

    // ──────────────────────────────────────────────────────────
    // 3) Farver (justér gerne til egne brandfarver):
    //    • goodColor = Orange/Gul (optimal lyseksponering)
    //    • badColor  = Lys blå (ikke optimal lyseksponering)
    //    • baseGrayColor = neutral grå for dage uden for DLMO‐dagen
    final Color goodColor        = const Color(0xFFFFAB00);  // Orange/gul
    final Color badColor         = const Color(0xFF5DADE2);  // Lys blå
    final Color baseGrayColor    = Colors.grey.shade600;     // Neutral, medium grå

    // ──────────────────────────────────────────────────────────
    // 4) Byg BarChartGroupData: én gruppe pr. dag i sortedDays
    final List<BarChartGroupData> groups = [];

    for (int idx = 0; idx < sortedDays.length; idx++) {
      final int day = sortedDays[idx];
      final double yVal = domMap[day]!.clamp(0.0, 100.0);

      // A) Hvis dag IKKE er recommendedDayOfMonth → farv baseGrayColor:
      if (day != recommendedDayOfMonth) {
        groups.add(
          BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: yVal,
                color: baseGrayColor,
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
        continue;
      }

      // B) Hvis dag ER recommendedDayOfMonth → tjek boost‐interval:
      final List<LightData> onlyThatDay = rawData.where((e) {
        return e.timestamp.day == recommendedDayOfMonth;
      }).toList();

      final List<LightData> inBoostWindow = onlyThatDay.where((e) {
        final double hour = e.timestamp.hour + (e.timestamp.minute / 60.0);
        return hour >= startBoostHour && hour < endBoostHour;
      }).toList();

      // Beregn gennemsnitlig eksponering (EDI * 100) i dette interval:
      double avgInWindow;
      if (inBoostWindow.isEmpty) {
        avgInWindow = 0.0;
      } else {
        avgInWindow = inBoostWindow
            .map((e) => (e.ediLux * 100.0).clamp(0.0, 100.0))
            .reduce((a, b) => a + b) /
            inBoostWindow.length;
      }

      // Tærskel = 50.0 (justér efter behov).
      // Hvis gennemsnit ≥ tærskel → goodColor (orange), ellers badColor (blå).
      final bool meetsThresholdInBoostWindow = avgInWindow >= 50.0;
      final Color barColor = meetsThresholdInBoostWindow
          ? goodColor
          : badColor;

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

    // ──────────────────────────────────────────────────────────
    // 5) Tegn BarChart‐widget’en for måned:
    return Card(
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Månedlig lysmængde",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
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
                  titlesData: FlTitlesData(
                    // BUND: vis hver dagstal i sortedDays
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < sortedDays.length) {
                            final String label = sortedDays[idx].toString();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                label,
                                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    // VENSTRE: procent‐labels
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            "${value.toInt()}%",
                            style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
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
