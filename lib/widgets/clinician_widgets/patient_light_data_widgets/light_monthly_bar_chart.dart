// lib/widgets/clinician_widgets/patient_light_data_widgets/light_monthly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';
import '../../../services/services/api_services.dart';

class LightMonthlyBarChart extends StatefulWidget {
  /// Patient-ID som vi henter data for
  final String patientId;

  /// rMEQ-score (bruges til at beregne DLMO og boost-vindue)
  final int rmeqScore;

  const LightMonthlyBarChart({
    Key? key,
    required this.patientId,
    required this.rmeqScore,
  }) : super(key: key);

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
      // Hent alle lysmålinger for denne patient (API’en returnerer rå JSON som List<LightData>)
      final List<LightData> fetched =
      await ApiService.fetchMonthlyLightData(patientId: widget.patientId);
      setState(() => _monthData = fetched);
    } catch (e) {
      setState(() => _errorMessage = 'Kunne ikke hente månedsdata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Loading‐indikator
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Fejlbesked, hvis hentning mislykkedes
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

    // 3) Hvis vi har hentet data (eller intet), tjek om listen er tom
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

    // ─────────────────────────────────────────────────────────────────
    // 4) Filtrér “denne måned” i UTC (for en sikkerheds skyld, selv om API'en skulle returnere kun denne måned)
    final nowUtc = DateTime.now().toUtc();
    final year = nowUtc.year;
    final month = nowUtc.month;
    final thisMonthData = rawData.where((e) {
      final tsUtc = e.capturedAt.toUtc();
      return tsUtc.year == year && tsUtc.month == month;
    }).toList();

    // ─────────────────────────────────────────────────────────────────
    // 5) GroupBy dag‐i‐måneden → Map<int, double> (1..31)
    final Map<int, double> domMap = LightUtils.groupByDayOfMonth(thisMonthData);
    final List<int> sortedDays = domMap.keys.toList()..sort();

    // ─────────────────────────────────────────────────────────────────
    // 6) Beregn DLMO-dag & boost-vindue vha. ChronotypeManager
    final ChronotypeManager chrono = ChronotypeManager(widget.rmeqScore);
    final int recommendedDay = chrono.getRecommendedTimes()['dlmo']!.toUtc().day;
    final double startBoostHour = chrono.lightboostStartHour;
    final double endBoostHour = chrono.lightboostEndHour;

    // ─────────────────────────────────────────────────────────────────
    // 7) Definér farver & tærskel
    const double threshold = 50.0;
    const Color goodColor = Color(0xFFFFAB00);   // Orange/gul = “opfyldt”
    const Color badColor = Color(0xFF5DADE2);    // Lys blå = “under”
    final Color neutralColor = Colors.grey.shade600; // Grå = “ikke DLMO‐dag”

    // ─────────────────────────────────────────────────────────────────
    // 8) Byg BarChartGroupData for hver dag i sortedDays
    final List<BarChartGroupData> groups = [];
    for (int idx = 0; idx < sortedDays.length; idx++) {
      final int day = sortedDays[idx];
      final double avgY = domMap[day]!.clamp(0.0, 100.0);

      // A) Hvis dag != recommendedDay → tegn neutral grå
      if (day != recommendedDay) {
        groups.add(
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

      // B) Hvis dag == recommendedDay → filtrér målinger for netop denne dag
      final List<LightData> onlyThatDay = thisMonthData.where((e) {
        return e.capturedAt.toUtc().day == day;
      }).toList();

      // Filtrér data inden for boost-vinduet (UTC-tid)
      final List<LightData> inWindow = onlyThatDay.where((e) {
        final DateTime tsUtc = e.capturedAt.toUtc();
        final double hourValue = tsUtc.hour + (tsUtc.minute / 60.0);
        return hourValue >= startBoostHour && hourValue < endBoostHour;
      }).toList();

      // Beregn gennemsnitlig EDI% * 100 i boost-vinduet
      double avgInWindow = 0.0;
      if (inWindow.isNotEmpty) {
        final double sum = inWindow
            .map((e) => (e.ediLux * 100.0).clamp(0.0, 100.0))
            .reduce((a, b) => a + b);
        avgInWindow = (sum / inWindow.length).clamp(0.0, 100.0);
      }

      // Vælg farve: ≥ threshold → goodColor, ellers badColor
      final bool meetsThreshold = avgInWindow >= threshold;
      final Color barColor = meetsThreshold ? goodColor : badColor;

      groups.add(
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

    // ─────────────────────────────────────────────────────────────────
    // 9) Tegn selve grafen med dag‐i‐måneden på x‐aksen
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

                  // Aksetitler
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
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              sortedDays[idx].toString(),
                              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                            ),
                          );
                        },
                      ),
                    ),

                    // VENSTRE (Y‐aksen): “0%, 20%, 40%…100%”
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
