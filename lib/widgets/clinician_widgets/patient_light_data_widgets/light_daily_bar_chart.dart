// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';

/// En “Day‐Light” bar‐graf, der grupperer lysdata per time (0–23).
/// Versionen her er skrevet til fl_chart v1.0.0+ (se pubspec.yaml).
class LightDailyBarChart extends StatelessWidget {
  /// Listen af rå lysmålinger (én LightData per timestamp).
  final List<LightData> rawData;

  const LightDailyBarChart({
    Key? key,
    required this.rawData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Vi antager, at LightUtils.groupByHourOfDay er deklareret som:
    //
    //    static List<double> groupByHourOfDay(List<LightData> data) { … }
    //
    // Hvis ikke, vil du få en fejl om, at metoden ikke findes.
    final List<double> hourlyAverages = LightUtils.groupByHourOfDay(rawData);

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
            // ---------------------------------------------------
            // 2) Titel
            // ---------------------------------------------------
            Text(
              'Dagligt lys (⌛)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),

            // ---------------------------------------------------
            // 3) Selve BarChart‐widget’en (pakket ind i et AspectRatio
            //    for at få et fornuftigt format)
            // ---------------------------------------------------
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  // ---------------------------------------------------
                  // 4) Definer Y‐aksens range
                  // ---------------------------------------------------
                  minY: 0,
                  maxY: 100,

                  // ---------------------------------------------------
                  // 5) (Valgfrit) Touch‐funktionalitet
                  // ---------------------------------------------------
                  barTouchData: BarTouchData(enabled: true),

                  // ---------------------------------------------------
                  // 6) Slå grid‐linjer og graf‐border fra
                  // ---------------------------------------------------
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),

                  // ---------------------------------------------------
                  // 7) TITLER i fl_chart v1.0.0+: AxisTitles → SideTitles
                  // ---------------------------------------------------
                  titlesData: FlTitlesData(
                    show: true,

                    // 7a) VENSTRE (Y‐aksen) titler
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,      // 0%, 20%, 40% … 100%
                        reservedSize: 32,  // Plads til f.eks. “20%”
                        getTitlesWidget:
                            (double value, TitleMeta meta) // Positional
                        {
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

                    // 7b) BUND (X‐aksen) titler – én label pr. 4. time
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 4,       // Vis “00:00”, “04:00”, “08:00” osv.
                        reservedSize: 32,  // Plads til teksten
                        getTitlesWidget:
                            (double value, TitleMeta meta) // NB: meta skal med
                        {
                          final int hour = value.toInt();
                          final String label =
                          (hour < 24) ? "${hour.toString().padLeft(2, '0')}:00" : "24:00";

                          // VIGTIGT: I fl_chart v1.0.0+ er konstruktøren:
                          //    SideTitleWidget({ required Widget child, required TitleMeta meta, … })
                          //
                          // *Ikke* `axisSide:` eller `side:`. Du skal altid give `meta: meta`.
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

                    // 7c) SKJUL “top” og “right” titler
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),

                  // ---------------------------------------------------
                  // 8) Selve BAR‐data: én gruppe (BarChartGroupData) pr. time 0..23
                  // ---------------------------------------------------
                  barGroups: List.generate(24, (int hour) {
                    // Hent “hourlyAverages[hour]” og clamp til [0..100]
                    final double rawValue = hourlyAverages[hour];
                    final double yValue = rawValue.clamp(0.0, 100.0);

                    // Bestem farven: ≥75% → grøn, ellers orange
                    final Color barColor = (yValue >= 75.0)
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF6D00);

                    return BarChartGroupData(
                      x: hour,
                      barRods: [
                        BarChartRodData(
                          toY: yValue,
                          width: 12.w,
                          color: barColor,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    );
                  }),

                  // ---------------------------------------------------
                  // 9) Mellemrum (spacing) mellem hver søjle
                  // ---------------------------------------------------
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
