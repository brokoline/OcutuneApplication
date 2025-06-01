// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'dart:math'; // Bruges kun, hvis du vil udvide med f.eks. min()/max()
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';

class LightWeeklyBarChart extends StatelessWidget {
  /// Hele listen af lysmålinger (alle datoer). Vi antager, at capturedAt er
  /// en DateTime uden isUtc=true, men reelt er UTC.
  final List<LightData> rawData;

  const LightWeeklyBarChart({
    super.key,
    required this.rawData,
  });

  @override
  Widget build(BuildContext context) {
    // ────────────────────────────────────────────────────────────
    // 1) Debug: print alle rawData‐timestamps (for at kontrollere isUtc/UTC‐konvertering)
    debugPrint("=== DEBUG: light_weekly_bar_chart RAW DATA START ===");
    for (final e in rawData) {
      final DateTime tsLocal = e.capturedAt;
      final DateTime tsUtc   = tsLocal.toUtc();
      debugPrint(
          " -> original parsed: $tsLocal (isUtc=${tsLocal.isUtc}), toUtc: $tsUtc, toLocal: ${tsLocal.toLocal()}");
    }
    debugPrint("=== DEBUG: light_weekly_bar_chart RAW DATA END ===");

    // ────────────────────────────────────────────────────────────
    // 2) Filtrér "denne uge" som mandag 00:00 UTC … søndag 23:59:59 UTC:

    // Tag aktuel tid i UTC
    final DateTime nowUtc       = DateTime.now().toUtc();
    final int currentWeekday    = nowUtc.weekday; // 1 = mandag … 7 = søndag

    // Beregn mandag kl. 00:00 i denne uge (UTC)
    final DateTime startOfWeek = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
    ).subtract(Duration(days: currentWeekday - 1));

    // Beregn søndag kl. 23:59:59 i denne uge (UTC)
    final DateTime endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    debugPrint(
        "=== DEBUG: denne uge (UTC) startOfWeek=$startOfWeek, endOfWeek=$endOfWeek ===");

    // Filtrer alle målinger, hvis UTC‐timestamp ligger i intervallet
    final List<LightData> thisWeekData = rawData.where((e) {
      final DateTime tsUtc = e.capturedAt.toUtc();
      return tsUtc.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
          tsUtc.isBefore(endOfWeek.add(const Duration(milliseconds: 1)));
    }).toList();

    debugPrint(
        "=== DEBUG: thisWeekData (${thisWeekData.length} items) timestamps ===");
    for (final e in thisWeekData) {
      final DateTime tsUtc = e.capturedAt.toUtc();
      debugPrint(" -> WEEK item UTC: $tsUtc   weekday=${tsUtc.weekday}");
    }
    debugPrint("=== DEBUG: thisWeekData END ===");

    // Hvis ingen data i denne uge (UTC), vis en besked i stedet for graf
    if (thisWeekData.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Center(
          child: Text(
            'Ingen lysmålinger i denne uge (UTC).',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ────────────────────────────────────────────────────────────
    // 3) Kald LightUtils.groupByWeekday på thisWeekData:
    //    (Returnerer Map<int,double> med nøgler 0=mandag … 6=søndag.)
    final Map<int, double> weekdayMap =
    LightUtils.groupByWeekday(thisWeekData);
    debugPrint("=== DEBUG: weekdayMap (0=man…6=søn) = $weekdayMap ===");

    // ────────────────────────────────────────────────────────────
    // 4) Byg en liste med 7 værdier (index=0..6). Hvis en nøgle mangler, sæt 0.0
    final List<double> dailyAverages = List<double>.generate(7, (i) {
      return (weekdayMap[i] ?? 0.0).clamp(0.0, 100.0);
    });
    debugPrint("=== DEBUG: dailyAverages (mandag..søndag) = $dailyAverages ===");

    // ────────────────────────────────────────────────────────────
    // 5) Definér tærskel og farver:
    const double threshold = 50.0;
    const Color goodColor = Color(0xFFFFAB00); // Orange/gul = ≥ 50%
    const Color badColor  = Color(0xFF5DADE2); // Lys blå  = < 50%

    // ────────────────────────────────────────────────────────────
    // 6) Byg BarChartGroupData – én bjælke pr. dag i rækkefølge 0..6
    final List<BarChartGroupData> barGroups = List.generate(7, (int idx) {
      final double yVal = dailyAverages[idx];
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
              toY: 100,
              color: Colors.grey.withOpacity(0.15),
            ),
          ),
        ],
      );
    });

    // ────────────────────────────────────────────────────────────
    // 7) Tegn grafen med danske ugedagsforkortelser:
    const List<String> weekdayLabels = [
      'Man',
      'Tir',
      'Ons',
      'Tor',
      'Fre',
      'Lør',
      'Søn'
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

            // – Selve grafen
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,

                  // Grid: vandrette linjer hver 20%
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

                  // Ingen kantlinjer
                  borderData: FlBorderData(show: false),

                  // Titler på akserne
                  titlesData: FlTitlesData(
                    show: true,

                    // VENSTRE (Y‐aksen): “0%,20%,40%,…100%”
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

                    // BUND (X‐aksen): “Man, Tir, … Søn”
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
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

                  // Bar‐grupperne
                  barGroups: barGroups,

                  // Afstand mellem søjlerne
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
