// lib/widgets/clinician_widgets/patient_light_data_widgets/light_monthly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';

class LightMonthlyBarChart extends StatelessWidget {
  /// Hele listen af lysmålinger (kan indeholde flere måneder).
  final List<LightData> rawData;

  /// rMEQ‐score (bruges til at beregne DLMO og boost‐vindue).
  final int rmeqScore;

  const LightMonthlyBarChart({
    super.key,
    required this.rawData,
    required this.rmeqScore,
  });

  @override
  Widget build(BuildContext context) {
    // ────────────────────────────────────────────────────────────────
    // 1) Filtrér alle målinger til KUN "denne måned" (år + måned = nuværende år og måned)
    final DateTime now = DateTime.now();
    final int thisYear  = now.year;
    final int thisMonth = now.month;

    final List<LightData> thisMonthData = rawData.where((e) {
      final ts = e.timestamp;
      return ts.year == thisYear && ts.month == thisMonth;
    }).toList();

    // ────────────────────────────────────────────────────────────────
    // 2) Gruppér per dag i måneden → Map<int dag, double procent>
    //    (her vil nøglerne være 1..31 for de dage, hvor vi rent faktisk har målinger)
    final Map<int, double> domMap = LightUtils.groupByDayOfMonth(thisMonthData);
    final List<int> sortedDays = domMap.keys.toList()..sort();
    // sortedDays er fx [1, 2, 3, 5, 6, 8, …] hvis fx. d.4 og d.7 ikke har målinger

    // ────────────────────────────────────────────────────────────────
    // 3) Hent DLMO‐dag og boost‐vindue fra ChronotypeManager (rmeqScore)
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final Map<String, DateTime> timeMap = chrono.getRecommendedTimes();
    final int recommendedDay    = timeMap['dlmo']!.day; // f.eks. 15
    final double startBoostHour = chrono.lightboostStartHour; // ex. 5.3
    final double endBoostHour   = chrono.lightboostEndHour;   // ex. 6.8

    // ────────────────────────────────────────────────────────────────
    // 4) Definér tærskel og farver:
    const double threshold = 50.0;              // ≥50 % = "god dag"
    const Color goodColor = Color(0xFFFFAB00);  // Orange/gul = opfyldt
    const Color badColor  = Color(0xFF5DADE2);  // Lys blå  = ikke fungerende
    final Color neutralColor = Colors.grey.shade600; // Grå for dage uden DLMO eller ingen data

    // ────────────────────────────────────────────────────────────────
    // 5) Opbyg en liste af BarChartGroupData – én gruppe pr. dag i sortedDays
    final List<BarChartGroupData> groups = [];

    for (int idx = 0; idx < sortedDays.length; idx++) {
      final int day = sortedDays[idx];
      final double dayAvgY = domMap[day]!.clamp(0.0, 100.0);

      // ──(A) Hent ALLE målinger for netop denne dag (i denne måned)
      final List<LightData> onlyThatDay = thisMonthData.where((e) {
        return e.timestamp.day == day;
      }).toList();

      // ──(B) Blandt dem, filtrér kun de tidsstempler, som ligger i boost‐intervallet:
      final List<LightData> inBoostWindow = onlyThatDay.where((e) {
        final double hourValue = e.timestamp.hour + (e.timestamp.minute / 60.0);
        return hourValue >= startBoostHour && hourValue < endBoostHour;
      }).toList();

      // ──(C) Beregn gennemsnitlig EDI*100 (0..100) i dette interval:
      double avgInWindow = 0.0;
      if (inBoostWindow.isNotEmpty) {
        avgInWindow = inBoostWindow
            .map((e) => (e.ediLux * 100.0).clamp(0.0, 100.0))
            .reduce((a, b) => a + b) / inBoostWindow.length;
      }

      // ──(D) Vælg farve: kun den DAG, der matcher DLMO (“recommendedDay”) skal farves
      //         – men farven baseres på om “avgInWindow >= threshold”.
      Color barColor = neutralColor;
      if (day == recommendedDay) {
        // Hvis netop DLMO-dag, farv orange/gul (opfyldt) eller lys blå (under)
        barColor = (avgInWindow >= threshold) ? goodColor : badColor;
      }

      // ──(E) Tilføj BarChartGroupData for denne dag:
      groups.add(
        BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: dayAvgY,
              color: barColor,
              width: 16.w,
              borderRadius: BorderRadius.circular(4.r),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.withOpacity(0.15), // baggrund for 100 %
              ),
            ),
          ],
          barsSpace: 4.w,
        ),
      );
    }

    // ────────────────────────────────────────────────────────────────
    // 6) Returnér BarChart med akser, grid, titler osv.
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titel
            Text(
              'Månedlig lysmængde',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // Graf i fast højde
            SizedBox(
              height: 200.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  // Sæt alignment, hvis du vil have "spaceBetween" i stedet for center
                  alignment: BarChartAlignment.spaceBetween,
                  backgroundColor: Colors.grey.shade900,
                  borderData: FlBorderData(show: false),

                  // Grid: kun vandrette linjer ved 20‐intervaller
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

                  // Titler på akserne
                  titlesData: FlTitlesData(
                    show: true,

                    // BUND (X‐aksen): én dato‐etiket pr. søjle
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx < 0 || idx >= sortedDays.length) {
                            return const SizedBox.shrink();
                          }
                          final String label = sortedDays[idx].toString();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // VENSTRE (Y‐aksen): “0%, 20%, 40%…”
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
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

                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  // Bar‐grupperne (én pr. dag)
                  barGroups: groups,

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
