import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/colors.dart';

class LightWeeklyBarChart extends StatelessWidget {
  final Map<String, double> luxPerDay;

  const LightWeeklyBarChart({super.key, required this.luxPerDay});

  @override
  Widget build(BuildContext context) {
    final keys = luxPerDay.keys.toList();
    final values = luxPerDay.values.toList();

    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ugentlig lysmængde",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  backgroundColor: generalBox,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          keys[value.toInt()],
                          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1000,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10.sp, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  barGroups: List.generate(keys.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: Colors.orangeAccent,
                          width: 14.w,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
