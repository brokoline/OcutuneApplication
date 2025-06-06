// lib/widgets/customer_widgets/customer_light_weekly_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/models/daily_light_summary_model.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../services/auth_storage.dart';


/// En “customer”-version af uge-diagrammet.
/// Henter altid data for patient “P3”. Hvis ingen JWT findes, vis en “Log ind”-prompt.
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
    // Hent JWT/token én gang
    _tokenFuture = AuthStorage.getToken();
  }

  /// Henter 7 daglige summeringer for patient 'P3'
  Future<void> _fetchWeekLightData(String token) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Brug metoden, der automatisk sætter Authorization-header
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
        // 1) Venter på token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 2) Fejl under hent af token
        if (snapshot.hasError) {
          return SizedBox(
            height: 200.h,
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
        // 3) Ingen token → vis login-prompt
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
                    'Du skal logge ind for at se ugentlige lysmålinger.',
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

        // 4) Token findes → hent data, hvis ikke allerede hentet
        if (_weekData == null && _errorMessage == null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchWeekLightData(token);
          });
        }

        // 5) Vis loader, hvis data hentes
        if (_isLoading) {
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 6) Hvis fejl ved hent
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

        // 7) Hent de 7 daglige summeringer
        final weeklyData = _weekData ?? [];
        if (weeklyData.isEmpty) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: Text(
                'Ingen lysmålinger i denne uge.',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // ──────────────────────────────────────────────────────────────
        // 8) Byg diagram baseret på de 7 dags-summeringer
        // Sortér (hvis ikke serveren sender i korrekt rækkefølge)
        weeklyData.sort((a, b) => a.day.compareTo(b.day));

        // Beregn procentsats: pctAbove = (countHighLight / totalMeasurements) * 100
        // pctBelow = 100 – pctAbove (eller 0.0, hvis totalMeasurements == 0)
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

        // Byg BarChartGroupData med to lag: blå = pctBelow, orange = pctAbove
        List<BarChartGroupData> barGroups = [];
        for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
          final double below = pctBelowList[dayIndex].clamp(0.0, 100.0);
          final double above = pctAboveList[dayIndex].clamp(0.0, 100.0);

          final summary = weeklyData[dayIndex];
          final bool hasData = summary.totalMeasurements > 0;

          if (!hasData) {
            // Hvis ingen data: vis en hel grå søjle op til 100%
            barGroups.add(
              BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: 100.0,
                    color: Colors.grey.shade600,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            );
          } else {
            // Ellers: blå nederst (pctBelow), orange øverst (pctAbove)
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
                        const Color(0xFF5DADE2), // blå
                      ),
                      BarChartRodStackItem(
                        below,
                        below + above, // = 100.0
                        const Color(0xFFFFAB00), // orange
                      ),
                    ],
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
        }

        // Danske labels Man→Tir→Ons→Tor→Fre→Lør→Søn
        const List<String> weekdayLabels = [
          'Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'
        ];

        // 9) Tegn kortet
        return Card(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ugentlig lysmængde',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 12.h),
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
                        getDrawingHorizontalLine: (y) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
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
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx > 6) return const SizedBox.shrink();
                              return SideTitleWidget(
                                meta: meta,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
