// lib/widgets/clinician_widgets/patient_light_data_widgets/light_monthly_bar_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';

class LightMonthlyBarChart extends StatelessWidget {
  // Hele listen af lysmålinger (kan indeholde andre måneder).
  final List<LightData> rawData;

  // rMEQ‐score (til at beregne DLMO og boost‐vindue).
  final int rmeqScore;

  const LightMonthlyBarChart({
    super.key,
    required this.rawData,
    required this.rmeqScore,
  });

  @override
  Widget build(BuildContext context) {
    // ─────────────────────────────────────────────────────────────
    // 1) Debug: print alle rawData‐timestamps (så vi ser, om isUtc=false
    //    og hvordan toUtc()/toLocal() opfører sig).
    debugPrint("=== DEBUG: light_monthly_bar_chart RAW DATA START ===");
    for (var i = 0; i < rawData.length; i++) {
      final e = rawData[i];
      final DateTime tsLocal = e.capturedAt;
      final DateTime tsUtc   = tsLocal.toUtc();
      final DateTime tsBack  = tsUtc.toLocal();
      debugPrint(
          " -> [${i.toString().padLeft(3)}] parsed: $tsLocal "
              "(isUtc=${tsLocal.isUtc}), toUtc: $tsUtc, toLocal(after toUtc): $tsBack"
      );
    }
    debugPrint("=== DEBUG: light_monthly_bar_chart RAW DATA END ===");

    // ─────────────────────────────────────────────────────────────
    // 2) Filtrér til KUN “denne måned” (år + måned = i dag) i UTC
    final DateTime nowUtc   = DateTime.now().toUtc();
    final int thisYearUtc   = nowUtc.year;
    final int thisMonthUtc  = nowUtc.month;

    // Saml alle målinger, der tilhører år/måned = denne måned (UTC)
    final List<LightData> thisMonthData = rawData.where((e) {
      final DateTime tsUtc = e.capturedAt.toUtc();
      return tsUtc.year == thisYearUtc && tsUtc.month == thisMonthUtc;
    }).toList();

    debugPrint(
        "‼️ MÅNEDLIG: total rawData‐antal = ${rawData.length}, "
            "thisMonthData‐antal = ${thisMonthData.length}"
    );
    if (thisMonthData.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Center(
          child: Text(
            'Ingen lysmålinger i denne måned (UTC).',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // 3) Kald LightUtils.groupByDayOfMonth på denne måneds data
    //    → Map<int,double> med “dag i måneden” som nøgle (1..31) og
    //      værdi = gennemsnitlig EDI% (0..100) den dag.
    final Map<int, double> domMap = LightUtils.groupByDayOfMonth(thisMonthData);
    debugPrint("‼️ MÅNEDLIG: domMap (dag→avg) = $domMap");

    // Lav en sorteret liste af de dage, der faktisk findes i domMap:
    final List<int> sortedDays = domMap.keys.toList()..sort();
    debugPrint("‼️ MÅNEDLIG: sortedDays = $sortedDays");

    // ─────────────────────────────────────────────────────────────
    // 4) Hent DLMO‐dag og boost‐vindue fra ChronotypeManager
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final Map<String, DateTime> timeMap = chrono.getRecommendedTimes();

    // DLMO‐dag (1..31)
    final int recommendedDay = timeMap['dlmo']!.toUtc().day;
    debugPrint("‼️ MÅNEDLIG: anbefalet DLMO‐dag (UTC‐dag) = $recommendedDay");

    // Boost‐vindue i timer (f.eks. 18.5 .. 20.2)
    final double startBoostHour = chrono.lightboostStartHour;
    final double endBoostHour   = chrono.lightboostEndHour;
    debugPrint(
        "‼️ MÅNEDLIG: lightboostStartHour = ${startBoostHour.toStringAsFixed(2)}, "
            "lightboostEndHour = ${endBoostHour.toStringAsFixed(2)}"
    );

    // ─────────────────────────────────────────────────────────────
    // 5) Definér tærskel og farver:
    const double threshold   = 50.0;               // 50% grænse inde i vinduet
    const Color goodColor    = Color(0xFFFFAB00);  // Orange/gul = “opfyldt”
    const Color badColor     = Color(0xFF5DADE2);  // Lys blå = “under”
    final Color neutralColor = Colors.grey.shade600; // Grå = “ikke DLMO‐dag”

    // ─────────────────────────────────────────────────────────────
    // 6) Byg BarChartGroupData – én gruppe for hver dag i sortedDays
    final List<BarChartGroupData> groups = [];

    for (int idx = 0; idx < sortedDays.length; idx++) {
      final int day = sortedDays[idx];
      final double dayAvgY = (domMap[day]!).clamp(0.0, 100.0);

      // A) Hvis dag != recommendedDay → sæt neutral grå farve
      if (day != recommendedDay) {
        groups.add(
          BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: dayAvgY,
                color: neutralColor,
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

      // B) Hvis dag == recommendedDay:
      //    1) Filtrér alle målinger for netop denne dag
      final List<LightData> onlyThatDay = thisMonthData.where((e) {
        final DateTime tsUtc = e.capturedAt.toUtc();
        return tsUtc.day == day;
      }).toList();

      debugPrint(
          "   → DLMO‐dag $day: onlyThatDay‐antal = ${onlyThatDay.length}"
      );

      //    2) Af de data, find kun dem inde i boost‐vindue (UTC‐time)
      final List<LightData> inBoostWindow = onlyThatDay.where((e) {
        final DateTime tsUtc = e.capturedAt.toUtc();
        final double hourValue =
            tsUtc.hour + (tsUtc.minute / 60.0);
        return hourValue >= startBoostHour && hourValue < endBoostHour;
      }).toList();

      debugPrint(
          "       → iBoostWindow‐antal = ${inBoostWindow.length}"
      );

      //    3) Beregn gennemsnit (ediLux*100) i det boostVindue:
      double avgInWindow = 0.0;
      if (inBoostWindow.isNotEmpty) {
        final double sum = inBoostWindow
            .map((e) => (e.ediLux * 100.0).clamp(0.0, 100.0))
            .reduce((a, b) => a + b);
        avgInWindow = (sum / inBoostWindow.length).clamp(0.0, 100.0);
      }
      debugPrint(
          "       → avgInWindow = ${avgInWindow.toStringAsFixed(2)}%"
      );

      //    4) Vælg farve: ≥ threshold → goodColor, ellers badColor
      final bool meetsThreshold = avgInWindow >= threshold;
      final Color barColor = meetsThreshold ? goodColor : badColor;

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
                color: Colors.grey.withOpacity(0.15),
              ),
            ),
          ],
          barsSpace: 4.w,
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // 7) Tegn selve grafen med dag‐i‐måneden langs X‐aksen
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
              'Månedlig lysmængde',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // – Grafen
            SizedBox(
              height: 200.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  alignment: BarChartAlignment.spaceBetween,
                  backgroundColor: Colors.grey.shade900,
                  borderData: FlBorderData(show: false),

                  // Grid (vandrette linjer ved 20%)
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

                  // Aksernes titler
                  titlesData: FlTitlesData(
                    show: true,

                    // BUND (X‐aksen): Vis “dag i måneden” (1,2,3,…)
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

                    // VENSTRE (Y‐aksen): “0%,20%,40%…100%”
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

                  // Bar‐grupperne
                  barGroups: groups,

                  // Afstand mellem grupperne
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
