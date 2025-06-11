import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/auth_storage.dart';
import '/theme/colors.dart';
import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../services/services/api_services.dart';

class CustomerLightDailyBarChart extends StatefulWidget {
  final int rmeqScore;

  const CustomerLightDailyBarChart({
    super.key,
    required this.rmeqScore,
  });

  @override
  State<CustomerLightDailyBarChart> createState() =>
      _CustomerLightDailyBarChartState();
}

class _CustomerLightDailyBarChartState extends State<CustomerLightDailyBarChart> {
  List<LightData>? _todayData;
  String? _errorMessage;
  bool _isLoading = false;
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = AuthStorage.getToken();
  }

  Future<void> _fetchTodayLightData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetched = await ApiService.fetchDailyLightData(patientId: 'P3');
      setState(() => _todayData = fetched);
    } catch (e) {
      setState(() => _errorMessage = 'Kunne ikke hente dagsdata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 180.h,
            child: Center(
              child: Text(
                'Fejl ved hentning af login‐status: ${snapshot.error}',
                style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final token = snapshot.data;
        if (token == null) {
          return SizedBox(
            height: 180.h,
            child: Container(
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Du skal logge ind for at se daglig lyseksponering.',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text(
                      'Log ind',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (_todayData == null && _errorMessage == null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchTodayLightData();
          });
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
                  color: const Color(0xFF4A4A4A),
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
                        reservedSize: 40,
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
            SizedBox(height: 22.h),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: const Color(0xFFFFAB00), size: 16.sp),
                      SizedBox(height: 14.h),
                      Icon(Icons.circle, color: const Color(0xFF5DADE2), size: 16.sp),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Tidspunkt med optimal lyseksponering",
                        style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                      ),
                      SizedBox(height: 14.h),
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
      },
    );
  }
}
