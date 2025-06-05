// lib/widgets/customer_widgets/customer_light_daily_bar_chart.dart

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
    Key? key,
    required this.rmeqScore,
  }) : super(key: key);

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
      final fetched =
      await ApiService.fetchDailyLightData(patientId: 'P3');
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
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200.h,
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
            height: 200.h,
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
                    style:
                    TextStyle(color: Colors.white70, fontSize: 14.sp),
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

        // Token findes → hent data, hvis ikke allerede hentet
        if (_todayData == null && _errorMessage == null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchTodayLightData();
          });
        }

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

        if (todayData.isNotEmpty) {
          debugPrint('Antal datapunkter i dag: ${todayData.length}');
        }

        final hourlyLux = LightUtils.groupByHourOfDay(todayData);
        double maxLux = hourlyLux.reduce(max).clamp(1.0, double.infinity);

        final groups = List<BarChartGroupData>.generate(24, (hourIndex) {
          final avgLux = hourlyLux[hourIndex];
          double pct = (avgLux / maxLux) * 100.0;
          pct = pct.clamp(0.0, 100.0);

          final bool hasEnoughLight = pct >= 50.0;
          final Color barColor = hasEnoughLight
              ? const Color(0xFFFFAB00)
              : const Color(0xFF5DADE2);

          return BarChartGroupData(
            x: hourIndex,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daglig lyseksponering (rMEQ: ${widget.rmeqScore})",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 150.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("100%",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text("80%",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text("60%",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text("40%",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text("20%",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text("0%",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                        ],
                      ),
                      SizedBox(width: 8.w),
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
                                    final hour = value.toInt();
                                    if (hour % 4 == 0 || hour == 23) {
                                      final label = hour == 23
                                          ? "23:59"
                                          : "${hour
                                          .toString()
                                          .padLeft(2, '0')}:00";
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
                              leftTitles: AxisTitles(
                                  sideTitles:
                                  SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles:
                                  SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles:
                                  SideTitles(showTitles: false)),
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
      },
    );
  }
}
