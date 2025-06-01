import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../controller/chronotype_controller.dart';
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
      final List<LightData> fetched =
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
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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

    if (_todayData != null && _todayData!.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            'Ingen lysmålinger i dag (UTC).',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final rawData = _todayData ?? [];

    // Beregn “i dag” i UTC
    final nowUtc = DateTime.now().toUtc();
    final todayYear = nowUtc.year;
    final todayMonth = nowUtc.month;
    final todayDay = nowUtc.day;

    // 1) Debug: vis antal rå målinger og eksempler på timestamps
    debugPrint("‼️ DAGLIG: total rawData‐antal = ${rawData.length}");
    if (rawData.isNotEmpty) {
      final n = rawData.length;
      debugPrint("   → Første 5 timestamps:");
      for (var i = 0; i < min(5, n); i++) {
        final d = rawData[i];
        debugPrint(
            "       [${i.toString().padLeft(3)}] ${d.capturedAt.toUtc().toIso8601String()}");
      }
      if (n > 5) {
        debugPrint("   → …");
        for (var i = max(5, n - 5); i < n; i++) {
          final d = rawData[i];
          debugPrint(
              "       [${i.toString().padLeft(3)}] ${d.capturedAt.toUtc().toIso8601String()}");
        }
      }
    }

    // 2) Filtrér “i dag” (UTC)
    final todayData = rawData.where((d) {
      final tsUtc = d.capturedAt.toUtc();
      return tsUtc.year == todayYear &&
          tsUtc.month == todayMonth &&
          tsUtc.day == todayDay;
    }).toList();

    debugPrint("‼️ DAGLIG: TODAYDATA‐antal = ${todayData.length}");
    if (todayData.isNotEmpty) {
      final buckets = List<int>.filled(24, 0);
      for (var d in todayData) {
        final h = d.capturedAt.toUtc().hour;
        buckets[h]++;
      }
      debugPrint("   → Antal målinger pr. time (UTC):");
      for (int h = 0; h < 24; h++) {
        if (buckets[h] > 0) {
          debugPrint("       Time $h:00 – $h:59  =>  ${buckets[h]} rækker");
        }
      }
    } else {
      debugPrint("   → Ingen målinger registreret i dag (UTC).");
    }

    // 3) Beregn hourly averages
    final hourlyAverages = LightUtils.groupByHourOfDay(todayData);
    debugPrint("‼️ DAGLIG: hourlyAverages = $hourlyAverages");

    // 4) Beregn boost-vindue (til farvelogik)
    final chrono = ChronotypeManager(widget.rmeqScore);
    final startBoostHour = chrono.lightboostStartHour;
    final endBoostHour = chrono.lightboostEndHour;
    debugPrint(
        "‼️ DAGLIG: Boost window hours -> startBoost: $startBoostHour, endBoost: $endBoostHour");

    // 5) Konstruer BarChartGroupData for 24 timer
    final groups = List<BarChartGroupData>.generate(24, (i) {
      final yVal = hourlyAverages[i].clamp(0.0, 100.0);
      final color = (yVal >= 50.0)
          ? const Color(0xFFFFAB00)
          : const Color(0xFF5DADE2);
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: yVal,
            color: color,
            width: 12.w,
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
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dagligt lys (⌛)",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  backgroundColor: const Color(0xFF2A2A2A),
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 24) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              "${idx.toString().padLeft(2, '0')}:00",
                              style:
                              TextStyle(color: Colors.white70, fontSize: 10.sp),
                            ),
                          );
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
                            style: TextStyle(fontSize: 10.sp, color: Colors.white54),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: groups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
