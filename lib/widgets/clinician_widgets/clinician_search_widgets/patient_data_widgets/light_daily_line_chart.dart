import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/light_data_model.dart';
import '../../../../theme/colors.dart';

class LightDailyLineChart extends StatelessWidget {
  final List<LightData> lightData;

  const LightDailyLineChart({super.key, required this.lightData});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> luxPoints = lightData
        .map((d) => FlSpot(
      d.capturedAt.hour + d.capturedAt.minute / 60,
      d.illuminance.toDouble(),
    ))
        .toList();

    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Lux over døgnet",
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 180.h,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  backgroundColor: generalBox,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 200,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10.sp, color: Colors.white70),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}:00',
                            style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: luxPoints,
                      isCurved: true,
                      color: Colors.amberAccent,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
