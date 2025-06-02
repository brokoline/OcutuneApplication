// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_bar_chart.dart

import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../services/services/api_services.dart';


class LightDailyBarChart extends StatefulWidget {
  final String patientId;
  final int rmeqScore;

  const LightDailyBarChart({
    Key? key,
    required this.patientId,
    required this.rmeqScore,
  }) : super(key: key);

  @override
  State<LightDailyBarChart> createState() => _LightDailyBarChartState();
}

class _LightDailyBarChartState extends State<LightDailyBarChart> {
  List<LightData>? _todayData;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTodayLightData();
  }

  Future<void> _fetchTodayLightData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched =
      await ApiService.fetchDailyLightData(patientId: widget.patientId);
      setState(() => _todayData = fetched);
    } catch (e) {
      setState(() => _errorMessage = 'Kunne ikke hente dagsdata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Loader
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Fejl
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

    // 3) Ingen data
    if (_todayData != null && _todayData!.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            'Ingen lysmålinger i dag (lokal tid).',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 4) Rå data
    final rawData = _todayData!;

    // 5) Filtrer “i dag” i lokal tid
    final nowLocal = DateTime.now();
    final todayYear = nowLocal.year;
    final todayMonth = nowLocal.month;
    final todayDay = nowLocal.day;

    final todayData = rawData.where((d) {
      final tsLocal = d.capturedAt.toLocal();
      return tsLocal.year == todayYear &&
          tsLocal.month == todayMonth &&
          tsLocal.day == todayDay;
    }).toList();

    // 6) Rå luks pr. time
    final hourlyLux = LightUtils.groupByHourOfDay(todayData);

    // 7) Find dagens makslux
    double maxLux = 0.0;
    for (final lux in hourlyLux) {
      if (lux > maxLux) maxLux = lux;
    }
    if (maxLux == 0.0) maxLux = 1.0; // undgå division med nul

    // 8) Byg bar‐grupperne
    final groups = List<BarChartGroupData>.generate(24, (i) {
      final avgLux = hourlyLux[i];
      double pct = (avgLux / maxLux) * 100.0;
      pct = pct.clamp(0.0, 100.0);

      // Blå hvis pct >= 50, ellers orange
      final isCloseEnough = pct >= 50.0;
      final barColor =
      isCloseEnough ? const Color(0xFF5DADE2) : const Color(0xFFFFAB00);

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pct,
            color: barColor,
            width: 8.w,
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

    // 9) Tegn Card + graf + legend
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel
            Text(
              "Dagligt lys (⌛)",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),

            // Graf (nu lavere højde)
            SizedBox(
              height: 150.h,
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          // Hvis time = 0,4,8,12,16,20 → vis “HH:00”
                          if (idx % 4 == 0 && idx < 24) {
                            final label = idx.toString().padLeft(2, '0') + ":00";
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
                          }
                          // Hvis sidst i døgnet → vis “23:59”
                          if (idx == 23) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                "23:59",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
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
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 4.w,
                  barGroups: groups,
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Legend‐boks (ingen overflow)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF353535),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blå legend‐linje
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5DADE2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Du ramte tæt på den anbefalede lyseksponering på dette tidspunkt.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5.sp,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Orange legend‐linje
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Mængden af lys på dette tidspunkt var ikke optimal.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5.sp,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ekstra bund‐margin
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}