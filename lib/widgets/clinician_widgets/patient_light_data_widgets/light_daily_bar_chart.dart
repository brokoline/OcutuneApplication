// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_bar_chart.dart

import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/theme/colors.dart';
import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../services/services/api_services.dart';

class LightDailyBarChart extends StatefulWidget {
  final String patientId;
  final int rmeqScore;

  const LightDailyBarChart({
    super.key,
    required this.patientId,
    required this.rmeqScore,
  });

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
      final fetched = await ApiService.fetchDailyLightData(patientId: widget.patientId);
      setState(() => _todayData = fetched);
    } catch (e) {
      setState(() => _errorMessage = 'Kunne ikke hente dagsdata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 160.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 160.h,
        child: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_todayData != null && _todayData!.isEmpty) {
      return SizedBox(
        height: 160.h,
        child: Center(
          child: Text(
            'Ingen lysmålinger i dag (lokal tid).',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final rawData = _todayData!;
    final nowLocal = DateTime.now();
    final todayData = rawData.where((d) {
      final tsLocal = d.capturedAt.toLocal();
      return tsLocal.year == nowLocal.year &&
          tsLocal.month == nowLocal.month &&
          tsLocal.day == nowLocal.day;
    }).toList();

    final hourlyLux = LightUtils.groupByHourOfDay(todayData);
    double maxLux = hourlyLux.reduce(max).clamp(1.0, double.infinity);

    final groups = List<BarChartGroupData>.generate(24, (i) {
      final avgLux = hourlyLux[i];
      double pct = (avgLux / maxLux) * 100.0;
      pct = pct.clamp(0.0, 100.0);

      final bool hasEnoughLight = pct >= 50.0;
      final Color barColor = hasEnoughLight
          ? const Color(0xFFFFAB00)
          : const Color(0xFF5DADE2);

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

    return Card(
      color: generalBox,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Daglig lyseksponering",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            // Percentage labels and chart
            SizedBox(
              height: 150.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("100%", style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                      Text("80%", style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                      Text("60%", style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                      Text("40%", style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                      Text("20%", style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                      Text("0%", style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                    ],
                  ),
                  SizedBox(width: 8.w),

                  // Expanded chart area
                  Expanded(
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
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx % 4 == 0 || idx == 23) {
                                  final label = idx == 23 ? "23:59" : "${idx.toString().padLeft(2, '0')}:00";
                                  return Text(
                                    label,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.sp,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        alignment: BarChartAlignment.spaceAround,
                        groupsSpace: 4.w,
                        barGroups: groups,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Legend
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: const Color(0xFFFFAB00),
                      size: 12.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Tidspunkt med optimal lyseksponering",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: const Color(0xFF5DADE2),
                      size: 12.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Tidspunkt med uoptimal lyseksponering",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}