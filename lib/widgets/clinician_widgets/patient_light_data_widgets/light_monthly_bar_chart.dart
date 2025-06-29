import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/light_data_model.dart';
import '../../../models/daily_light_summary_model.dart';
import '../../../services/services/api_services.dart';

class LightMonthlyBarChart extends StatefulWidget {
  final String patientId;

  const LightMonthlyBarChart({
    super.key,
    required this.patientId,
  });

  @override
  State<LightMonthlyBarChart> createState() => _LightMonthlyBarChartState();
}

class _LightMonthlyBarChartState extends State<LightMonthlyBarChart> {
  List<DailyLightSummary>? _monthlySummary;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyLightData();
  }

  Future<void> _fetchMonthlyLightData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patientIdForLightData = kDebugMode ? 'P3' : widget.patientId;
      final summaryList = await ApiService.fetchMonthlyLightData(patientId: patientIdForLightData);
      if (!mounted) return;
      setState(() => _monthlySummary = summaryList);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Kunne ikke hente månedsdata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<DailyLightSummary> _aggregateMonthly(List<LightData> lightDataList) {
    final Map<DateTime, Map<String, int>> counts = {};
    for (final d in lightDataList) {
      final date = DateTime(d.capturedAt.year, d.capturedAt.month, d.capturedAt.day);
      final isHigh = d.melanopicEdi >= 250;
      counts.putIfAbsent(date, () => {"high": 0, "low": 0, "total": 0});
      counts[date]!["total"] = counts[date]!["total"]! + 1;
      if (isHigh) {
        counts[date]!["high"] = counts[date]!["high"]! + 1;
      } else {
        counts[date]!["low"] = counts[date]!["low"]! + 1;
      }
    }
    return counts.entries.map((entry) {
      return DailyLightSummary(
        day: entry.key,
        countHighLight: entry.value["high"]!,
        countLowLight: entry.value["low"]!,
        totalMeasurements: entry.value["total"]!,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 180.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 180.h,
        child: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final summaryList = _monthlySummary ?? [];
    if (summaryList.isEmpty) {
      return SizedBox(
        height: 180.h,
        child: Center(
          child: Text(
            'Ingen lysmålinger denne måned.',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final today = DateTime.now();
    final year = today.year;
    final month = today.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    Map<int, DailyLightSummary> summaryByDay = {
      for (var d in summaryList) d.day.day: d
    };

    List<BarChartGroupData> barGroups = [];
    for (int day = 1; day <= daysInMonth; day++) {
      bool isFuture = DateTime(year, month, day).isAfter(today);
      final summary = summaryByDay[day];
      if (isFuture) break;

      if (summary == null || summary.totalMeasurements == 0) {
        barGroups.add(
          BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: 0,
                color: const Color(0xFF444444),
                width: 14.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          ),
        );
      } else {
        double pctAbove = (summary.countHighLight / summary.totalMeasurements) * 100.0;
        double pctBelow = 100.0 - pctAbove;
        barGroups.add(
          BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: 100.0,
                width: 14.w,
                borderRadius: BorderRadius.circular(4.r),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    pctBelow,
                    const Color(0xFF5DADE2),
                  ),
                  BarChartRodStackItem(
                    pctBelow,
                    100,
                    const Color(0xFFFFAB00),
                  ),
                ],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: const Color(0xFF444444),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(
            "Månedlig lysmængde",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                getDrawingHorizontalLine: (y) => FlLine(
                  color: Colors.white24,
                  strokeWidth: 1,
                ),
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
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 1 || idx > daysInMonth) return const SizedBox.shrink();
                      if (idx == 1 || idx == daysInMonth || idx % 3 == 0) {
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            '$idx',
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
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 8.w,
              barGroups: barGroups,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: const Color(0xFFFFAB00), size: 18.sp),
                  SizedBox(width: 10.w),
                  Text(
                    "Tidspunkt med optimal lyseksponering",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: const Color(0xFF5DADE2), size: 18.sp),
                  SizedBox(width: 10.w),
                  Text(
                    "Tidspunkt med uoptimal lyseksponering",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
