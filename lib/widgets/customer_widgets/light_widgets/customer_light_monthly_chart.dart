import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/auth_storage.dart';
import '/theme/colors.dart';
import '../../../models/daily_light_summary_model.dart';
import '../../../services/services/api_services.dart';

class CustomerLightMonthlyBarChart extends StatefulWidget {
  const CustomerLightMonthlyBarChart({super.key});

  @override
  State<CustomerLightMonthlyBarChart> createState() =>
      _CustomerLightMonthlyBarChartState();
}

class _CustomerLightMonthlyBarChartState
    extends State<CustomerLightMonthlyBarChart> {
  List<DailyLightSummary>? _monthlySummary;
  String? _errorMessage;
  bool _isLoading = false;
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = AuthStorage.getToken();
  }

  Future<void> _fetchMonthlyLightData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryList =
      await ApiService.fetchMonthlyLightData(patientId: 'P3');
      if (!mounted) return;
      setState(() => _monthlySummary = summaryList);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Kunne ikke hente månedsdata: $e');
    } finally {
      if (!mounted) return;
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
                    'Du skal logge ind for at se månedlige lysmålinger.',
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

        if (_monthlySummary == null && _errorMessage == null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchMonthlyLightData();
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
              child: Center(
                child: Text(
                  'Månedlig lyseksponering',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
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
            SizedBox(height: 10.h),
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
      },
    );
  }
}
