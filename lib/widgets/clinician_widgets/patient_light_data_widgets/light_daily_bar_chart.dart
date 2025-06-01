// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';

class LightDailyBarChart extends StatelessWidget {
  /// Rå liste af lysmålinger (én LightData pr. timestamp).
  final List<LightData> rawData;

  /// rMEQ‐score (bruges af ChronotypeManager til at finde boost‐interval i timer).
  final int rmeqScore;

  const LightDailyBarChart({
    super.key,
    required this.rawData,
    required this.rmeqScore,
  });

  @override
  Widget build(BuildContext context) {
    // ──────────────────────────────────────────────────────────
    // 1) FILTRÉR rawData til "kun i DAG" (DateTime.now().year/month/day)
    final DateTime now = DateTime.now();
    final int todayYear  = now.year;
    final int todayMonth = now.month;
    final int todayDay   = now.day;

    final List<LightData> todayData = rawData.where((e) {
      final ts = e.timestamp;
      return ts.year == todayYear && ts.month == todayMonth && ts.day == todayDay;
    }).toList();

    // ──────────────────────────────────────────────────────────
    // 2) Beregn gennemsnit pr. time (0..23) i procent (0..100) for i dag.
    List<double> hourlyAverages = LightUtils.groupByHourOfDay(todayData);

    // Hvis utils‐metoden ikke allerede fylder op til 24 elementer, gør vi det her:
    if (hourlyAverages.length < 24) {
      final List<double> filled = List<double>.filled(24, 0.0);
      for (int i = 0; i < hourlyAverages.length && i < 24; i++) {
        filled[i] = hourlyAverages[i];
      }
      hourlyAverages = filled;
    }

    // ──────────────────────────────────────────────────────────
    // 3) Find det anbefalede “light boost”‐vindue via ChronotypeManager:
    final ChronotypeManager chrono = ChronotypeManager(rmeqScore);
    final double startBoostHour = chrono.lightboostStartHour; // fx 5.3
    final double endBoostHour   = chrono.lightboostEndHour;   // fx 6.8

    // ──────────────────────────────────────────────────────────
    // 4) Definer farver og tærskel:
    const double threshold = 50.0;               // Procent‐grænse inde i boost‐window
    const Color goodColor      = Color(0xFFFFAB00); // Orange/gul   = “optimal eksponering”
    const Color badColor       = Color(0xFF5DADE2); // Lys blå      = “under threshold”
    final Color outsideColor   = Colors.grey.shade700; // Neutral grå  = “uden for vinduet”

    // ──────────────────────────────────────────────────────────
    // 5) Byg én BarChartGroupData pr. time (0..23)
    final List<BarChartGroupData> barGroups = List.generate(24, (int hour) {
      final double rawValue = hourlyAverages[hour].clamp(0.0, 100.0);

      // A) Tjek om denne time er i boost‐intervallet:
      final bool isInBoostWindow = (hour + 0.0 >= startBoostHour && hour + 0.0 < endBoostHour);

      if (!isInBoostWindow) {
        // Hvis UDENFOR boost‐vindue: tegn neutral grå
        return BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: rawValue,
              width: 12.w,
              color: outsideColor,
              borderRadius: BorderRadius.zero,
            ),
          ],
        );
      }

      // B) Hvis i boost‐interval: farv orange hvis ≥threshold, ellers blå
      final bool meetsThreshold = rawValue >= threshold;
      final Color barColor      = meetsThreshold ? goodColor : badColor;

      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: rawValue,
            width: 12.w,
            color: barColor,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });

    // ──────────────────────────────────────────────────────────
    // 6) Returnér BarChart‐widgeten
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // – Titel
            Text(
              'Dagligt lys (⌛)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),

            // – Selve grafen i et AspectRatio så den får flot bredde/højde
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,

                  // Mulighed for at trykke/tappe/hover
                  barTouchData: BarTouchData(enabled: true),

                  // Tegn både vandrette og lodrette grid‐linjer
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (double y) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (double x) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      );
                    },
                  ),

                  // Fjern kantlinjer omkring grafen
                  borderData: FlBorderData(show: false),

                  // Titler (labels) på akserne
                  titlesData: FlTitlesData(
                    show: true,

                    // VENSTRE (Y‐aksen): Vis “0%, 20%, 40% … 100%”
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

                    // BUND (X‐aksen): Vis kun hver 3. time for at undgå overlap
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int hour = value.toInt();
                          if (hour < 0 || hour > 23) {
                            return const SizedBox.shrink();
                          }
                          final String label = "${hour.toString().padLeft(2, '0')}:00";
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

                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  // Bar‐grupperne (24 styk)
                  barGroups: barGroups,

                  // Lidt afstand mellem søjlerne
                  groupsSpace: 2.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
