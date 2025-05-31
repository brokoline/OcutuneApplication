// lib/widgets/clinician_widgets/patient_light_data_widgets/light_daily_line_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../controller/chronotype_controller.dart';
import '../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../models/light_data_model.dart';
import '../../../theme/colors.dart';

class LightDailyLineChart extends StatefulWidget {
  const LightDailyLineChart({Key? key}) : super(key: key);

  @override
  State<LightDailyLineChart> createState() => _LightDailyLineChartState();
}

class _LightDailyLineChartState extends State<LightDailyLineChart> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientDetailViewModel>();
    final allData = vm.rawLightData;

    // Hent rMEQ direkte fra ViewModel‐getter (double). Konverter til int, da ChronotypeManager forventer int.
    final int rmeqScoreInt = (vm.rmeqScore).toInt();
    final chrono = ChronotypeManager(rmeqScoreInt);
    final timeWindows = chrono.getRecommendedTimes();

    final dailySpots = _computeDailySpots(allData);
    final weeklyBars = _computeWeeklyBars(allData);
    final monthlyBars = _computeMonthlyBars(allData);

    final chartViews = [
      _buildLineChart(dailySpots, timeWindows),
      _buildBarChart(weeklyBars),
      _buildBarChart(monthlyBars),
    ];

    return Card(
      elevation: 6,
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentPage == 0
                  ? 'Daglig lyseksponering'
                  : _currentPage == 1
                  ? 'Ugentlig lysmængde'
                  : 'Månedlig lysmængde',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 280.h,
              child: PageView.builder(
                itemCount: chartViews.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 32.w),
                  child: chartViews[i],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _buildColorLegend(_currentPage),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                chartViews.length,
                    (index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: CircleAvatar(
                    radius: 5.r,
                    backgroundColor:
                    _currentPage == index ? Colors.blueAccent : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _computeDailySpots(List<LightData> allData) {
    final now = DateTime.now();
    final midnightToday = DateTime(now.year, now.month, now.day);
    final yesterdayMidnight = midnightToday.subtract(const Duration(days: 1));
    final yesterdayEnd = midnightToday.subtract(const Duration(milliseconds: 1));

    final yesterdayData = allData.where((entry) {
      final dtLocal = entry.capturedAt.toLocal();
      return dtLocal.isAfter(yesterdayMidnight.subtract(const Duration(milliseconds: 1))) &&
          dtLocal.isBefore(yesterdayEnd.add(const Duration(milliseconds: 1)));
    }).toList();

    double maxEdi = 0;
    for (var entry in yesterdayData) {
      final ediVal = entry.melanopicEdi.toDouble();
      if (ediVal > maxEdi) {
        maxEdi = ediVal;
      }
    }
    if (maxEdi == 0) return [];

    return yesterdayData.map((entry) {
      final dtLocal = entry.capturedAt.toLocal();
      final hourDecimal = dtLocal.hour + dtLocal.minute / 60.0;
      final yValue = (entry.melanopicEdi.toDouble() / maxEdi) * 100;
      return FlSpot(hourDecimal, yValue);
    }).toList();
  }

  List<BarChartGroupData> _computeWeeklyBars(List<LightData> allData) {
    final Map<int, List<double>> grouped = {};
    for (var entry in allData) {
      final dtLocal = entry.capturedAt.toLocal();
      final weekday = dtLocal.weekday;
      grouped.putIfAbsent(weekday, () => []).add(entry.melanopicEdi.toDouble());
    }

    return grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      // Her opdager vi, at clamp(0,100) giver en num – vi konverterer til double:
      final double toY = (avg.clamp(0, 100) as num).toDouble();
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: toY,
            color: toY >= 75 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
            width: 12.w,
            borderRadius: BorderRadius.circular(4.r),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _computeMonthlyBars(List<LightData> allData) {
    final Map<int, List<double>> grouped = {};
    for (var entry in allData) {
      final dtLocal = entry.capturedAt.toLocal();
      final day = dtLocal.day;
      grouped.putIfAbsent(day, () => []).add(entry.melanopicEdi.toDouble());
    }

    int index = 0;
    return grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final double toY = (avg.clamp(0, 100) as num).toDouble();
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: toY,
            color: toY >= 75 ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
            width: 12.w,
            borderRadius: BorderRadius.circular(4.r),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLineChart(
      List<FlSpot> spots, Map<String, DateTime> timeWindows) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22.h,
              interval: 4,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}:00',
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 45.w,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (timeWindows.containsKey('dlmo'))
              VerticalLine(
                x: timeWindows['dlmo']!.hour.toDouble() +
                    timeWindows['dlmo']!.minute / 60.0,
                color: Colors.redAccent.withOpacity(0.6),
                strokeWidth: 1.5,
                dashArray: [5, 5],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.bottomCenter,
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                  labelResolver: (_) => 'DLMO',
                ),
              ),
            if (timeWindows.containsKey('lightboost_start'))
              VerticalLine(
                x: timeWindows['lightboost_start']!.hour.toDouble() +
                    timeWindows['lightboost_start']!.minute / 60.0,
                color: Colors.yellowAccent.withOpacity(0.6),
                strokeWidth: 1.2,
                dashArray: [3, 3],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.bottomCenter,
                  style: TextStyle(fontSize: 10, color: Colors.yellowAccent),
                  labelResolver: (_) => 'Bright Light Start',
                ),
              ),
            if (timeWindows.containsKey('lightboost_end'))
              VerticalLine(
                x: timeWindows['lightboost_end']!.hour.toDouble() +
                    timeWindows['lightboost_end']!.minute / 60.0,
                color: Colors.yellowAccent.withOpacity(0.6),
                strokeWidth: 1.2,
                dashArray: [3, 3],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.bottomCenter,
                  style: TextStyle(fontSize: 10, color: Colors.yellowAccent),
                  labelResolver: (_) => 'Bright Light End',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<BarChartGroupData> bars) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
              reservedSize: 45.w,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars
            .map((bar) => BarChartGroupData(
          x: bar.x,
          barRods: [
            BarChartRodData(
              toY: bar.barRods[0].toY,
              color: bar.barRods[0].color,
              width: 12.w,
              borderRadius: BorderRadius.circular(4.r),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        ))
            .toList(),
      ),
    );
  }

  Widget _buildColorLegend(int chartType) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem(
            Colors.blueAccent,
            chartType == 0 ? 'Optimal lyseksponering' : 'Aktuel lyseksponering',
          ),
          SizedBox(height: 4.h),
          _buildLegendItem(
            Colors.orangeAccent,
            chartType == 0 ? 'Anbefalet område' : 'Maksimalt muligt',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
