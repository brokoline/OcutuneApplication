// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_bar_chart.dart

import 'dart:math'; // For min() og max()
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';

class LightDailyBarChart extends StatelessWidget {
  /// Hele listen af lysmålinger (UTC), men Dart parser dem som isUtc=false.
  final List<LightData> rawData;

  /// rMEQ‐score (bruges til at beregne boost‐vindue i timer).
  final int rmeqScore;

  const LightDailyBarChart({
    super.key,
    required this.rawData,
    required this.rmeqScore,
  });

  @override
  Widget build(BuildContext context) {
    // Vi regner i “rene” UTC (DateTime.toUtc()), så vi fanger alle målinger, selvom
    // d.capturedAt er parsed med isUtc=false.
    final DateTime nowUtc   = DateTime.now().toUtc();
    final int todayYear     = nowUtc.year;
    final int todayMonth    = nowUtc.month;
    final int todayDay      = nowUtc.day;

    // ───────────────────────────────────────────────────────────────────────────
    // 1) Udskriv antal rå‐målinger:
    debugPrint("‼️ DAGLIG: total rawData‐antal = ${rawData.length}");

    // 2) Udskriv kun de første og de sidste 5 timestamps, hvis der er flere end 5:
    if (rawData.isNotEmpty) {
      final int n = rawData.length;
      debugPrint("   → Første 5 timestamps:");
      for (var i = 0; i < min(5, n); i++) {
        final d = rawData[i];
        debugPrint("       [${i.toString().padLeft(3)}] ${d.capturedAt.toUtc().toIso8601String()}");
      }
      if (n > 5) {
        debugPrint("   → …");
        for (var i = max(5, n - 5); i < n; i++) {
          final d = rawData[i];
          debugPrint("       [${i.toString().padLeft(3)}] ${d.capturedAt.toUtc().toIso8601String()}");
        }
      }
    }

    // ───────────────────────────────────────────────────────────────────────────
    // 3) Filtrér “i dag” (UTC) og udskriv, hvor mange der er:
    final List<LightData> todayData = rawData.where((d) {
      final DateTime tsUtc = d.capturedAt.toUtc();
      return tsUtc.year  == todayYear &&
          tsUtc.month == todayMonth &&
          tsUtc.day   == todayDay;
    }).toList();

    debugPrint("‼️ DAGLIG: TODAYDATA‐antal = ${todayData.length}");
    if (todayData.isNotEmpty) {
      // 3a) Udskriv fordelingen pr. time (UTC), uden at printe hver eneste række:
      final buckets = List<int>.filled(24, 0);
      for (var d in todayData) {
        final int h = d.capturedAt.toUtc().hour;
        buckets[h]++;
      }
      debugPrint("   → Antal målinger pr. time (UTC):");
      for (int h = 0; h < 24; h++) {
        if (buckets[h] > 0) {
          debugPrint("       Time $h:00 – $h:59  =>  ${buckets[h]} rækker");
        }
      }
    } else {
      debugPrint("   → Ingen målinger registreret i dag (UTC).");
    }

    // ───────────────────────────────────────────────────────────────────────────
    // 4) Beregn hourly averages (LightUtils.groupByHourOfDay)
    final List<double> hourlyAverages = LightUtils.groupByHourOfDay(todayData);
    debugPrint("‼️ DAGLIG: hourlyAverages = $hourlyAverages");

    // ───────────────────────────────────────────────────────────────────────────
    // 5) Beregn boost‐vindue (eksempelvis til brug for farve‐skifte):
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final double startBoostHour = chrono.lightboostStartHour;
    final double endBoostHour   = chrono.lightboostEndHour;
    debugPrint("‼️ DAGLIG: Boost window hours -> startBoost: $startBoostHour, endBoost: $endBoostHour");

    // ───────────────────────────────────────────────────────────────────────────
    // 6) Byg selve BarChart‐gruppen:
    final List<BarChartGroupData> groups = List.generate(24, (int i) {
      final double yVal = hourlyAverages[i].clamp(0.0, 100.0);

      // Eksempel på at tjekke “boost‐vindue”: Hvis vi ville farve y‐værdier i boost‐timen:
      // final bool inBoostWindow = (i >= startBoostHour && i < endBoostHour);
      // final Color barColor = inBoostWindow
      //     ? const Color(0xFFFFAB00) // GUL, hvis i ligger i boost‐timen
      //     : const Color(0xFF5DADE2); // BLÅ ellers
      //
      // Men her vælger vi farve ud fra procent‐threshold:
      final Color barColor = (yVal >= 50.0)
          ? const Color(0xFFFFAB00)
          : const Color(0xFF5DADE2);

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: yVal,
            color: barColor,
            width: 12.w,
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

    // ───────────────────────────────────────────────────────────────────────────
    // 7) Tegn Card + BarChart:
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dagligt lys (⌛)",
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
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx < 0 || idx >= 24) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              "${idx.toString().padLeft(2, '0')}:00",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                              ),
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
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white54,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: groups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
