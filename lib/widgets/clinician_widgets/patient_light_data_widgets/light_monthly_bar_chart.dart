// lib/widgets/clinician_widgets/patient_light_data_widgets/light_monthly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';
import '../../../services/services/api_services.dart';

class LightMonthlyBarChart extends StatefulWidget {
  /// Patient-ID, som vi henter data for
  final String patientId;

  /// rMEQ-score (bruges til at beregne DLMO og boost-vindue)
  final int rmeqScore;

  const LightMonthlyBarChart({
    super.key,
    required this.patientId,
    required this.rmeqScore,
  });

  @override
  State<LightMonthlyBarChart> createState() => _LightMonthlyBarChartState();
}

class _LightMonthlyBarChartState extends State<LightMonthlyBarChart> {
  List<LightData>? _monthData;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMonthLightData();
  }

  Future<void> _fetchMonthLightData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<LightData> fetched = await ApiService.fetchMonthlyLightData(
        patientId: widget.patientId,
      );
      setState(() {
        _monthData = fetched;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kunne ikke hente månedsdata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Vis loading‐indikator mens vi henter
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Vis fejlbesked hvis hentning fejlede
    if (_errorMessage != null) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 3) Hvis vi har hentet, men datalisten er tom
    final rawData = _monthData ?? [];
    if (rawData.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            'Ingen lysmålinger i denne måned (UTC).',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────────
    // 4) Filtrer “denne måned” udfra UTC-tid (selvom API burde returnere præcis den måned)
    final nowUtc = DateTime.now().toUtc();
    final int year = nowUtc.year;
    final int month = nowUtc.month;
    final List<LightData> thisMonthData = rawData.where((d) {
      final ts = d.capturedAt.toUtc();
      return ts.year == year && ts.month == month;
    }).toList();

    // ───────────────────────────────────────────────────────────────────────────
    // 5) Gruppen: dag‐i‐måneden → Map<int, double> med gennemsnitlig ediLux per dag
    //    Brug den KORREKTE metode: groupByDayOfMonthLux
    final Map<int, double> domMap = LightUtils.groupByDayOfMonthLux(thisMonthData);

    //    Sortér dagene (1,2,3,…). Nu indeholder domMap nøglerne (1..31) for dem, der rent faktisk findes i data.
    final List<int> sortedDays = domMap.keys.toList()..sort();

    // ───────────────────────────────────────────────────────────────────────────
    // 6) Identificér DLMO-dagen og boost-vinduet vha. ChronotypeManager
    final ChronotypeManager chrono = ChronotypeManager(widget.rmeqScore);

    //    a) DLMO-tidspunkt som DateTime (UTC). Her tager vi blot “day”-delen
    final DateTime dlmoUtc = chrono.getRecommendedTimes()['dlmo']!.toUtc();
    final int recommendedDay = dlmoUtc.day;

    //    b) Boost‐vindue i antal timer fra midnat (eksempel: 7.5 = kl. 07:30 UTC)
    final double startBoostHour = chrono.lightboostStartHour;
    final double endBoostHour = chrono.lightboostEndHour;

    // ───────────────────────────────────────────────────────────────────────────
    // 7) Find månedens maksimale gennemsnitlige ediLux (for normalisering til procent)
    final double maxAvgLux = domMap.values.reduce((a, b) => a > b ? a : b);

    // ───────────────────────────────────────────────────────────────────────────
    // 8) Opsæt farve‐ og tærskel‐konstanter
    const double thresholdPct = 50.0;            // ≥ 50 % giver orange
    const Color goodColor = Color(0xFFFFAB00);    // Orange = “opfyldt”
    const Color badColor = Color(0xFF5DADE2);     // Blå = “under”
    final Color neutralColor = Colors.grey.shade600; // Grå = ikke‐DLMO‐dag

    // ───────────────────────────────────────────────────────────────────────────
    // 9) Byg BarChartGroupData ‐ én søjle pr. dag i sortedDays
    final List<BarChartGroupData> barGroups = [];

    for (int idx = 0; idx < sortedDays.length; idx++) {
      final int day = sortedDays[idx];
      final double avgLuxForDay = domMap[day]!; // fx 150.3 (lux)

      // 9a) Beregn hvilken procent af månedens maksimale dags‐gennemsnit, denne dags‐værdi udgør:
      final double avgY = (maxAvgLux > 0)
          ? ((avgLuxForDay / maxAvgLux) * 100.0).clamp(0.0, 100.0)
          : 0.0;

      // 9b) Hvis Dagen IKKE er DLMO‐dagen → neutral grå-søjle
      if (day != recommendedDay) {
        barGroups.add(
          BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: avgY,
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
          ),
        );
        continue;
      }

      // 9c) Hvis Dagen ER DLMO‐dagen → tjek, om “boost‐vindues‐gennemsnittet” når tærskel
      //     Step 1: Filtrér udelukkende data fra DLMO‐dagen
      final List<LightData> onlyThatDay = thisMonthData.where((d) {
        return d.capturedAt.toUtc().day == day;
      }).toList();

      //     Step 2: Filtrér data inden for boost-vinduet (UTC-ti)
      final List<LightData> inWindow = onlyThatDay.where((d) {
        final DateTime tsUtc = d.capturedAt.toUtc();
        final double hourFraction = tsUtc.hour + (tsUtc.minute / 60.0);
        return hourFraction >= startBoostHour && hourFraction < endBoostHour;
      }).toList();

      //     Step 3: Beregn gennemsnitlig “EDI%” i boost-vinduet:
      //       – Vi regner med, at ediLux allerede er "EDI i lux" og ønsker at udtrykke det som procent (0..100).
      //       – Her tager vi (ediLux * 100).clamp(0..100) for hver måling, lægger sammen og dividerer med antal målinger.
      double avgInWindowPct = 0.0;
      if (inWindow.isNotEmpty) {
        final double sumPct = inWindow
            .map((d) => (d.ediLux * 100.0).clamp(0.0, 100.0))
            .reduce((a, b) => a + b);
        avgInWindowPct = (sumPct / inWindow.length).clamp(0.0, 100.0);
      }

      //     Step 4: Vælg farve udfra tærskel:
      final bool meetsThreshold = avgInWindowPct >= thresholdPct;
      final Color barColor = meetsThreshold ? goodColor : badColor;

      //     Step 5: Tilføj stakit (baseret på avgY, men farvelagt orange/blå):
      barGroups.add(
        BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: avgY,
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
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────────
    // 10) Tegn selve grafen med dag‐i‐måneden på x‐aksen
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
              'Månedlig lysmængde',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // Graf‐widget
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

                  // Aksetitler
                  titlesData: FlTitlesData(
                    show: true,

                    // BUND (X‐aksen): Vis “dag i måneden”
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
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              sortedDays[idx].toString(),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // VENSTRE (Y‐aksen): “0%, 20%, 40% … 100%”
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
                  barGroups: barGroups,

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
