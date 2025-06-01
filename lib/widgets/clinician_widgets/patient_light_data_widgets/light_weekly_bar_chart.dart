// lib/widgets/clinician_widgets/patient_light_data_widgets/light_weekly_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/colors.dart';

class LightWeeklyBarChart extends StatelessWidget {
  final Map<String, double> luxPerDay;

  const LightWeeklyBarChart({
    Key? key,
    required this.luxPerDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = luxPerDay.keys.toList();
    final values = luxPerDay.values.toList();

    return Card(
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          return Text(
                            keys[idx],
                            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
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
                  barGroups: List.generate(keys.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].clamp(0, 100),
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
