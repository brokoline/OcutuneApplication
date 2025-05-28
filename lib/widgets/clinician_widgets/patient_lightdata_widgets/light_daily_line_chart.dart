import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controller/chronotype_controller.dart';
import '../../../theme/colors.dart';

class LightDailyLineChart extends StatefulWidget {
  final List<FlSpot> lightData;
  final int totalScore;
  final List<BarChartGroupData> weeklyBars;
  final List<BarChartGroupData> monthlyBars;

  const LightDailyLineChart({
    super.key,
    required this.lightData,
    required this.totalScore,
    required this.weeklyBars,
    required this.monthlyBars,
  });

  @override
  State<LightDailyLineChart> createState() => _LightDailyLineChartState();
}

class _LightDailyLineChartState extends State<LightDailyLineChart> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final chrono = ChronotypeManager(widget.totalScore);
    final timeWindows = chrono.getRecommendedTimes();

    final List<Widget> chartViews = [
      _buildLineChart(widget.lightData, timeWindows),
      _buildBarChart(widget.weeklyBars),
      _buildBarChart(widget.monthlyBars),
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
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 220.h, // Øget højde for bedre plads
              child: PageView.builder(
                itemCount: chartViews.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(right: 24.w), // Mere padding til højre
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
                    backgroundColor: _currentPage == index ? Colors.blueAccent : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, Map<String, DateTime> timeWindows) {
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
                '${value.toInt()}',
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40.w, // Øget plads til y-akse
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
              reservedSize: 40.w, // Øget plads til y-akse
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
        barGroups: bars.map((bar) => BarChartGroupData(
          x: bar.x,
          barRods: [
            BarChartRodData(
              toY: bar.barRods[0].toY,
              color: Colors.blueAccent,
              width: 12.w,
              borderRadius: BorderRadius.circular(4.r),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        )).toList(),
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