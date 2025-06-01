// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_line_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/colors.dart';

class LightDailyLineChart extends StatefulWidget {
  final List<FlSpot> lightData;
  final int totalScore;
  final List<BarChartGroupData> weeklyBars;
  final List<BarChartGroupData> monthlyBars;

  const LightDailyLineChart({
    Key? key,
    required this.lightData,
    required this.totalScore,
    required this.weeklyBars,
    required this.monthlyBars,
  }) : super(key: key);

  @override
  _LightDailyLineChartState createState() => _LightDailyLineChartState();
}

class _LightDailyLineChartState extends State<LightDailyLineChart> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDailyExposureChart(),
      _buildWeeklyExposureChart(),
      _buildMonthlyExposureChart(),
    ];

    return Card(
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              _chartTitle(),
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            SizedBox(height: 180.h, child: pages[_currentIndex]),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (index) => GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.blueAccent : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _chartTitle() {
    switch (_currentIndex) {
      case 0:
        return "Daily light exposure";
      case 1:
        return "Weekly light exposure";
      case 2:
        return "Monthly light exposure";
      default:
        return "";
    }
  }

  Widget _buildDailyExposureChart() {
    return LineChart(
      LineChartData(
        backgroundColor: generalBox,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, _) {
                final int hour = value.toInt();
                final label = hour < 10 ? '0$hour:00' : '$hour:00';
                return Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 20,
              getTitlesWidget: (value, _) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.lightData,
            isCurved: true,
            barWidth: 3.w,
            color: Colors.blueAccent,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyExposureChart() {
    return BarChart(
      BarChartData(
        backgroundColor: generalBox,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                // x=1..7 => Mon..Sun
                const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final idx = value.toInt();
                return Text(
                  idx >= 1 && idx <= 7 ? weekDays[idx - 1] : '',
                  style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                );
              },
            ),
          ),
        ),
        barGroups: widget.weeklyBars,
      ),
    );
  }

  Widget _buildMonthlyExposureChart() {
    return BarChart(
      BarChartData(
        backgroundColor: generalBox,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 5,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                // Vi har sorteret keys fra 0 og opefter; vis “day+1” som label:
                return Text(
                  '${idx + 1}',
                  style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                );
              },
            ),
          ),
        ),
        barGroups: widget.monthlyBars,
      ),
    );
  }
}
