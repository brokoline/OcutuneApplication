import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/models/daily_light_summary_model.dart';

import '../../../services/auth_storage.dart';

class CustomerLightWeeklyBarChart extends StatefulWidget {
  const CustomerLightWeeklyBarChart({Key? key}) : super(key: key);

  @override
  State<CustomerLightWeeklyBarChart> createState() =>
      _CustomerLightWeeklyBarChartState();
}

class _CustomerLightWeeklyBarChartState
    extends State<CustomerLightWeeklyBarChart> {
  List<DailyLightSummary>? _weekData;
  String? _errorMessage;
  bool _isLoading = false;
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = AuthStorage.getToken();
  }

  Future<void> _fetchWeekLightData(String token) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await ApiService.fetchWeeklyLightData(patientId: 'P3');
      setState(() => _weekData = fetched);
    } catch (e) {
      setState(() =>
      _errorMessage = 'Fejl ved hentning af ugentlige data: $e');
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
                'Fejl ved hentning af login-status: ${snapshot.error}',
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
                    'Du skal logge ind for at se ugentlige lysmålinger.',
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

        if (_weekData == null && _errorMessage == null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchWeekLightData(token);
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

        final weeklyData = _weekData ?? [];
        if (weeklyData.isEmpty) {
          return SizedBox(
            height: 180.h,
            child: Center(
              child: Text(
                'Ingen lysmålinger i denne uge.',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        weeklyData.sort((a, b) => a.day.compareTo(b.day));

        final List<double> pctAboveList = List<double>.generate(7, (i) {
          final summary = weeklyData[i];
          if (summary.totalMeasurements == 0) return 0.0;
          return (summary.countHighLight / summary.totalMeasurements) * 100.0;
        });
        final List<double> pctBelowList = List<double>.generate(7, (i) {
          final summary = weeklyData[i];
          if (summary.totalMeasurements == 0) return 0.0;
          return 100.0 - pctAboveList[i];
        });

        List<BarChartGroupData> barGroups = [];
        for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
          final double below = pctBelowList[dayIndex].clamp(0.0, 100.0);
          final double above = pctAboveList[dayIndex].clamp(0.0, 100.0);

          final summary = weeklyData[dayIndex];
          final bool hasData = summary.totalMeasurements > 0;

          if (!hasData) {
            barGroups.add(
              BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    color: const Color(0xFF4A4A4A),
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            );
          } else {
            barGroups.add(
              BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                    rodStackItems: [
                      BarChartRodStackItem(
                        0,
                        below,
                        const Color(0xFF5DADE2),
                      ),
                      BarChartRodStackItem(
                        below,
                        below + above,
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

        const List<String> weekdayLabels = [
          'Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                'Ugentlig lysmængde',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 180.h,
              child: Padding(
                padding: EdgeInsets.only(right: 20.w), // ekstra plads til søndag
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
                          reservedSize: 40, // større så søndag aldrig cuttes
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx > 6) return const SizedBox.shrink();
                            return Padding(
                              padding: EdgeInsets.only(
                                top: 6.h,
                                right: idx == 6 ? 14.w : 0, // ekstra plads til SØN
                              ),
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
