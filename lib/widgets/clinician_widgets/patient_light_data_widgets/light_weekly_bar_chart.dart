// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../services/services/api_services.dart';

class LightWeeklyBarChart extends StatelessWidget {
  final String patientId;

  const LightWeeklyBarChart({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LightData>>(
      future: ApiService.fetchWeeklyLightData(patientId: patientId),
      builder: (context, snapshot) {
        // 1) Loader‐tilstand
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 2) Fejl‐tilstand
        if (snapshot.hasError) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: Text(
                'Fejl ved hentning af ugentlige data: ${snapshot.error}',
                style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 3) Hent rådata
        final rawData = snapshot.data ?? [];
        if (rawData.isEmpty) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: Text(
                'Ingen lysmålinger i denne uge.',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // ──────────────────────────────────────────────────────────────
        // 4) Vi vil opdele hver dag i to portioner: “optimalt lys” vs. “ikke-optimalt lys”.
        //    Definer en fast tærskel i ediLux (melanopicEdi), f.eks. 150.
        const double luxThreshold = 150.0;

        // 5) Filtrer råData per lokal ugedag (1=Mandag..7=Søndag). Byg to lister:
        //    - countTotalPerDay[weekdayIndex]: hvor mange målinger der er på netop den dag.
        //    - countAbovePerDay[weekdayIndex]: hvor mange af målingerne den dag der er ≥ luxThreshold.
        final List<int> countTotalPerDay = List.filled(7, 0);
        final List<int> countAbovePerDay = List.filled(7, 0);

        for (final d in rawData) {
          final lokalWeekday = d.capturedAt.toLocal().weekday - 1; // 0=Man..6=Søn
          countTotalPerDay[lokalWeekday]++;

          if (d.ediLux >= luxThreshold) {
            countAbovePerDay[lokalWeekday]++;
          }
        }

        // 6) Beregn procent for hver dag i rækkefølgen 0=Man..6=Søn:
        //    pctAbove = (countAbove / countTotal) * 100
        //    pctBelow = 100.0 - pctAbove (hvis countTotal>0, ellers sat til 0)
        final List<double> pctAboveList = List<double>.generate(7, (i) {
          if (countTotalPerDay[i] == 0) return 0.0;
          return (countAbovePerDay[i] / countTotalPerDay[i]) * 100.0;
        });

        final List<double> pctBelowList = List<double>.generate(7, (i) {
          // Hvis ingen data, sæt til 0.0
          if (countTotalPerDay[i] == 0) return 0.0;
          final double above = pctAboveList[i];
          return (100.0 - above);
        });

        // DEBUG: kan udskrives i konsol, hvis man vil se tallet for hver dag:
        /*
        for (int i = 0; i < 7; i++) {
          final navn = ["Man", "Tir", "Ons", "Tor", "Fre", "Lør", "Søn"][i];
          debugPrint(
            "ℹ️ $navn: total=${countTotalPerDay[i]}, "
            "above=${countAbovePerDay[i]}, "
            "pctAbove=${pctAboveList[i].toStringAsFixed(1)}, "
            "pctBelow=${pctBelowList[i].toStringAsFixed(1)}"
          );
        }
        */

        // 7) Byg BarChartGroupData med stacked rods. Vi vil tegne uge‐søjler i rækkefølge
        //    TOR→FRE→LØR→SØN→MAN→TIR→ONS. Derfor omrokeres vores (Man..Søn)-data til netop den rækkefølge.
        List<BarChartGroupData> barGroups = [];
        final List<int> reorder = [3, 4, 5, 6, 0, 1, 2]; // Tor, Fre, Lør, Søn, Man, Tir, Ons

        for (int idx = 0; idx < 7; idx++) {
          final int dayIndex = reorder[idx];       // 0..6 (Man..Søn), men i TOR→FRE→…
          final double pctBelow = pctBelowList[dayIndex].clamp(0.0, 100.0);

          // Hvis ingen data (countTotalPerDay[dayIndex]==0), kan vi farve hele søjlen som grå
          if (countTotalPerDay[dayIndex] == 0) {
            barGroups.add(
              BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    color: Colors.grey.shade600,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            );
          } else {
            // Byg en rod med to stack‐items:
            barGroups.add(
              BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                    rodStackItems: [
                      // Nederste del: pctBelow (blå)
                      BarChartRodStackItem(
                        0,
                        pctBelow,
                        const Color(0xFF5DADE2),
                      ),
                      // Øverste del: pctBelow→100 (orange)
                      BarChartRodStackItem(
                        pctBelow,
                        100.0,
                        const Color(0xFFFFAB00),
                      ),
                    ],
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: Colors.grey.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            );
          }
        }

        // 8) Danske labels i korrekt rækkefølge (TOR→FRE→LØR→SØN→MAN→TIR→ONS)
        const List<String> weekdayLabels = [
          'Tor', 'Fre', 'Lør', 'Søn', 'Man', 'Tir', 'Ons'
        ];

        // 9) Tegn selve grafen
        return Card(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titel
                Text(
                  'Ugentlig lysmængde',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 12.h),

                // Graf‐området
                SizedBox(
                  height: 180.h,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 100,
                      backgroundColor: Colors.transparent,
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
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
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
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
                      alignment: BarChartAlignment.spaceAround,
                      groupsSpace: 8.w,
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
