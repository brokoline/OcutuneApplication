import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      final patientIdForLightData = kDebugMode ? 'P3' : widget.patientId;

      final fetched = await ApiService.fetchDailyLightData(patientId: patientIdForLightData);

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

    if (_todayData == null && _errorMessage == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTodayLightData();
      });
      return SizedBox(
        height: 180.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
    if (_todayData != null && _todayData!.isEmpty) {
      return SizedBox(
        height: 180.h,
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
    final nowLocal = DateTime.now().toLocal();
    final todayData = rawData.where((d) {
      final tsLocal = d.capturedAt.toLocal();
      final match = tsLocal.year == nowLocal.year &&
          tsLocal.month == nowLocal.month &&
          tsLocal.day == nowLocal.day;
      return match;
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
              color: const Color(0xFF4A4A4A), // Mørkere grå baggrund
            ),
          ),
        ],
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(
            "Daglig lyseksponering",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 180.h,
          child: Padding(
            padding: EdgeInsets.only(right: 20.w), // <-- Ekstra højre-padding
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
                      reservedSize: 44,
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
                      reservedSize: 40, // <-- større reservedSize
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx % 4 == 0) {
                          final label = "${idx.toString().padLeft(2, '0')}:00";
                          return Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Text(
                              label,
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
                groupsSpace: 4.w,
                barGroups: groups,
              ),
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
