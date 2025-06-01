// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';

/// Daglig søjlegraf, der farver timer i boost‐interval orange/gul (god) eller lys blå (ikke‐god),
/// og prikker de andre timer (uden for vinduet) som medium grå.
class LightDailyBarChart extends StatelessWidget {
  /// Rå liste af lysmålinger (én LightData pr. timestamp).
  final List<LightData> rawData;

  /// rMEQ‐score (bruges til at finde det anbefalede boost‐vindue).
  final int rmeqScore;

  const LightDailyBarChart({
    Key? key,
    required this.rawData,
    required this.rmeqScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Beregn gennemsnit per time (0..23).
    List<double> hourlyAverages = LightUtils.groupByHourOfDay(rawData);
    if (hourlyAverages.length < 24) {
      // Fyld op til 24 elementer med 0.0, hvis gruppen er kortere
      List<double> filled = List<double>.filled(24, 0.0);
      for (int i = 0; i < hourlyAverages.length && i < 24; i++) {
        filled[i] = hourlyAverages[i];
      }
      hourlyAverages = filled;
    }

    // 2) Hent anbefalet “light boost” vindue via ChronotypeManager
    final chrono = ChronotypeManager(rmeqScore);
    final double startBoostHour = chrono.lightboostStartHour; // fx 5.3
    final double endBoostHour   = chrono.lightboostEndHour;   // fx 6.8

    // 3) Farver og tærskel
    const double threshold = 50.0;             // Procent‐grænse i boost‐vindue
    const Color goodColor = Color(0xFFFFAB00);  // Orange/gul = optimal
    const Color badColor  = Color(0xFF5DADE2);  // Lys blå = under threshold
    final Color outsideColor = Colors.grey.shade600; // Medium grå = uden for vindue

    // 4) Byg BarChartGroupData for hver time (0..23)
    final List<BarChartGroupData> barGroups = List.generate(24, (int hour) {
      final double rawValue = hourlyAverages[hour].clamp(0.0, 100.0);

      final bool isInBoostWindow = (hour + 0.0 >= startBoostHour && hour + 0.0 < endBoostHour);
      if (!isInBoostWindow) {
        // uden for boostvindue = medium grå
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

      // i boostvindue → tjek threshold
      final bool meetsThreshold = rawValue >= threshold;
      final Color barColor = meetsThreshold ? goodColor : badColor;

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

    // 5) Returnér BarChart‐widget’en
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
            // Titel
            Text(
              'Dagligt lys (⌛)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),

            // Grafsnit i et AspectRatio for pæn visning
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  // Tap‐/hover‐funktion
                  barTouchData: BarTouchData(enabled: true),

                  // Tegn både horisontale og lodrette gridlinjer
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (y) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (x) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      );
                    },
                  ),

                  // Fjern kantlinjer omkring grafen
                  borderData: FlBorderData(show: false),

                  // Titler/labels på akserne
                  titlesData: FlTitlesData(
                    show: true,

                    // VENSTRE (Y‐aksen)
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

                    // BUND (X‐aksen): vis kun hver 3. time (interval:3)
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int hour = value.toInt();
                          if (hour < 0 || hour > 23) return const SizedBox.shrink();
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

                    // SKJUL top og right
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  barGroups: barGroups,
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
