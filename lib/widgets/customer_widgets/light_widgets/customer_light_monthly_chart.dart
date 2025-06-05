// lib/widgets/customer_widgets/customer_light_monthly_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/auth_storage.dart';
import '/theme/colors.dart';
import '/models/light_data_model.dart';
import '/utils/light_utils.dart';
import '/controller/chronotype_controller.dart';
import '/services/services/api_services.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomerLightMonthlyBarChart extends StatefulWidget {
  final int rmeqScore;
  final String chronotype;

  const CustomerLightMonthlyBarChart({
    Key? key,
    required this.rmeqScore,
    required this.chronotype,
  }) : super(key: key);

  @override
  State<CustomerLightMonthlyBarChart> createState() =>
      _CustomerLightMonthlyBarChartState();
}

class _CustomerLightMonthlyBarChartState
    extends State<CustomerLightMonthlyBarChart> {
  List<LightData>? _monthData;
  String? _errorMessage;
  bool _isLoading = false;
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = AuthStorage.getToken();
  }

  Future<void> _fetchMonthLightData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetched =
      await ApiService.fetchMonthlyLightData(patientId: 'P3');
      setState(() {
        _monthData = fetched;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kunne ikke hente månedsdata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                'Fejl ved hent af login‐status: ${snapshot.error}',
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
                    'Du skal logge ind for at se månedlige lysmål.',
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

        if (_monthData == null && _errorMessage == null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchMonthLightData();
          });
        }

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

        // Filtrér “denne måned” udfra UTC (år+måned)
        final nowUtc = DateTime.now().toUtc();
        final year = nowUtc.year;
        final month = nowUtc.month;
        final List<LightData> thisMonthData = rawData.where((d) {
          final ts = d.capturedAt.toUtc();
          return ts.year == year && ts.month == month;
        }).toList();

        // Byg Map<dag, gennemsnitlig ediLux> for denne måned
        final domMap = LightUtils.groupByDayOfMonthLux(thisMonthData);
        final sortedDays = domMap.keys.toList()..sort();

        // Lave en ChronotypeManager baseret på kundens rMEQ og chronotype
        final ChronotypeManager chrono =
        ChronotypeManager(widget.rmeqScore);

        // DLMO‐dato i UTC (vi tager “dag” ud af DateTime)
        final DateTime dlmoUtc = chrono.getRecommendedTimes()['dlmo']!.toUtc();
        final int recommendedDay = dlmoUtc.day;

        final double startBoostHour = chrono.lightboostStartHour;
        final double endBoostHour = chrono.lightboostEndHour;

        final double maxAvgLux =
        domMap.values.reduce((a, b) => a > b ? a : b);

        const thresholdPct = 50.0;
        const Color goodColor = Color(0xFFFFAB00);
        const Color badColor = Color(0xFF5DADE2);
        final neutralColor = Colors.grey.shade600;

        final List<BarChartGroupData> barGroups = [];

        for (int idx = 0; idx < sortedDays.length; idx++) {
          final day = sortedDays[idx];
          final avgLuxForDay = domMap[day]!;

          final avgY = (maxAvgLux > 0)
              ? ((avgLuxForDay / maxAvgLux) * 100.0).clamp(0.0, 100.0)
              : 0.0;

          if (day != recommendedDay) {
            barGroups.add(
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

          // Hvis det er DLMO‐dag → check boost‐vindue
          final onlyThatDay = thisMonthData.where((d) {
            return d.capturedAt.toUtc().day == day;
          }).toList();

          final inWindow = onlyThatDay.where((d) {
            final tsUtc = d.capturedAt.toUtc();
            final double hourFrac =
                tsUtc.hour + (tsUtc.minute / 60.0);
            return hourFrac >= startBoostHour &&
                hourFrac < endBoostHour;
          }).toList();

          double avgInWindowPct = 0.0;
          if (inWindow.isNotEmpty) {
            final sumPct = inWindow
                .map((d) => (d.ediLux * 100.0).clamp(0.0, 100.0))
                .reduce((a, b) => a + b);
            avgInWindowPct =
                (sumPct / inWindow.length).clamp(0.0, 100.0);
          }

          final meetsThreshold = avgInWindowPct >= thresholdPct;
          final barColor = meetsThreshold ? goodColor : badColor;

          barGroups.add(
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

        return Card(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Månedlig lysmængde (rMEQ: ${widget.rmeqScore}, '
                      'Chronotype: ${widget.chronotype})',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 200.h,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 100,
                      alignment: BarChartAlignment.spaceBetween,
                      backgroundColor: Colors.grey.shade900,
                      borderData: FlBorderData(show: false),
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
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 32,
                            getTitlesWidget:
                                (double value, TitleMeta meta) {
                              final idx = value.toInt();
                              if (idx < 0 ||
                                  idx >= sortedDays.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  sortedDays[idx].toString(),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.sp,
                                  ),
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
                            getTitlesWidget:
                                (double value, TitleMeta meta) {
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
                        topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: barGroups,
                      groupsSpace: 4.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
