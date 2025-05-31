// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../models/light_data_model.dart';
import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';

class LightWeeklyBarChart extends StatelessWidget {
  const LightWeeklyBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Hent ViewModel via Provider
    final vm = context.watch<PatientDetailViewModel>();

    // 2) Hent rå lysdata (Liste<LightData>) fra ViewModel
    final List<LightData> rawData = vm.rawLightData;

    // 3) Definér de seneste 7 dage (i lokal tid), inklusive i dag som dag 0
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Vi vil gerne have dage: mandag, tirsdag, onsdag, torsdag, fredag, lørdag, søndag.
    // Men vi vil samle data for “seneste 7 døgn” – så brug lokal tid start på midnat.
    final Map<String, double> sumIlluminancePerDay = {};

    // Initialiser alle 7 dage med 0.0:
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = DateFormat.E('da').format(day); // 'Man', 'Tir', etc. på dansk
      sumIlluminancePerDay[key] = 0.0;
    }

    // 4) Gennemløb rawData og læg hver målings illuminance til den rette dag,
    //     men kun for de seneste 7 dage (inkl. i dag):
    for (final entry in rawData) {
      final dtLocal = entry.capturedAt.toLocal();
      final dayOnly = DateTime(dtLocal.year, dtLocal.month, dtLocal.day);
      final diff = today.difference(dayOnly).inDays;
      if (diff >= 0 && diff < 7) {
        // Hent korrekt nøgle (fx 'Man', 'Tir', etc.)
        final key = DateFormat.E('da').format(dayOnly);
        sumIlluminancePerDay[key] =
            (sumIlluminancePerDay[key] ?? 0.0) + entry.illuminance.toDouble();
      }
    }

    // 5) Byg to parallelle lists: én for keys (i den rækkefølge vi vil vise dem),
    //     og én for de tilsvarende værdier.
    final keys = sumIlluminancePerDay.keys.toList();
    final values = sumIlluminancePerDay.values.toList();

    return Card(
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ugentlig lysmængde",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  backgroundColor: generalBox,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _computeHorizontalInterval(values),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= keys.length) return const SizedBox();
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              keys[idx],
                              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _computeHorizontalInterval(values),
                        reservedSize: 40.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(keys.length, (i) {
                    final double barHeight = values[i].clamp(0, double.infinity);
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: barHeight,
                          color: Colors.orangeAccent,
                          width: 14.w,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Udregn en passende intervalværdi til y-aksens grid baseret på maksimum‐værdi.
  double _computeHorizontalInterval(List<double> values) {
    if (values.isEmpty) return 1.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    // Hvis max < 100, interval 20; ellers interval = max/5 rundet op.
    if (maxVal <= 100) return 20;
    final interval = (maxVal / 5).ceilToDouble();
    return interval;
  }
}
