import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/theme/colors.dart';
import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';
import '../../../services/services/api_services.dart';
import '../../../controller/chronotype_controller.dart';

/// LightScoreCard viser en donut med 24 time-segmenter,
/// farvet efter faktisk lysdata i løbet af dagen med faste lux-grænser.
class LightScoreCard extends StatefulWidget {
  final String patientId;
  final int meqScore;
  final int rmeqScore;

  const LightScoreCard({
    Key? key,
    required this.patientId,
    required this.meqScore,
    required this.rmeqScore,
  }) : super(key: key);

  @override
  _LightScoreCardState createState() => _LightScoreCardState();
}

class _LightScoreCardState extends State<LightScoreCard> {
  List<LightData>? _todayData;
  bool _isLoading = false;
  String? _error;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _todayData = await ApiService.fetchDailyLightData(patientId: widget.patientId);
    } catch (e) {
      _error = 'Fejl ved hentning af lysdata: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
    );

    if (_isLoading) return SizedBox(height: 200.h, child: Center(child: CircularProgressIndicator()));
    if (_error != null) return SizedBox(height: 200.h, child: Center(child: Text(_error!, style: TextStyle(color: Colors.redAccent, fontSize: 14.sp))));
    if (_todayData == null || _todayData!.isEmpty) {
      return SizedBox(height: 200.h, child: Center(child: Text('Ingen lysmålinger i dag.', style: TextStyle(color: Colors.white70, fontSize: 14.sp))));
    }

    final now = DateTime.now();
    final today = _todayData!
        .where((d) =>
    d.capturedAt.toLocal().year == now.year &&
        d.capturedAt.toLocal().month == now.month &&
        d.capturedAt.toLocal().day == now.day)
        .toList();

    // Gruppe pr. time
    final hourlyLux = LightUtils.groupByHourOfDay(today);

    // Faste lux-grænser (juster efter ønsket mål)
    const lowThresholdLux = 20.0;
    const midThresholdLux = 200.0;
    const highThresholdLux = 500.0;

    // Farver for hver zone
    final lowColor = Colors.blue[900]!;    // < lowThreshold
    final midColor = Colors.lightBlue;     // lowThreshold–midThreshold
    final highColor = Colors.yellow;       // midThreshold–highThreshold
    final bestColor = Colors.orangeAccent; // > highThreshold
    final futureColor = Colors.white.withOpacity(0.08);

    // Byg PieChart-segmenter for hver time
    List<PieChartSectionData> sections = [];
    for (int hour = 0; hour < 24; hour++) {
      final lux = hourlyLux[hour];
      late Color segColor;
      if (hour < now.hour + 1) {
        if (lux < lowThresholdLux) {
          segColor = lowColor;
        } else if (lux < midThresholdLux) {
          segColor = midColor;
        } else if (lux < highThresholdLux) {
          segColor = highColor;
        } else {
          segColor = bestColor;
        }
      } else {
        segColor = futureColor;
      }

      sections.add(PieChartSectionData(
        color: segColor,
        value: 1,
        radius: 70.w,
        showTitle: false,
      ));
    }

    // Beregn procent af "best" timer i de målte
    final measuredHours = min(now.hour + 1, 24);
    final bestCount = hourlyLux
        .take(measuredHours)
        .where((lux) => lux >= highThresholdLux)
        .length;
    final percent = (bestCount / measuredHours * 100).toInt();

    // Tekstfarve baseret på Chronotype
    final chronoLabel = ChronotypeManager(widget.rmeqScore).getChronotypeLabel();
    final chronoColor = _getChronotypeColor(chronoLabel);

    return Card(
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 8,
      shadowColor: bestColor.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lys-score', style: titleStyle),
            SizedBox(height: 16.h),
            Center(
              child: SizedBox(
                height: 180.w,
                width: 180.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 50.w,
                        startDegreeOffset: -90,
                        sections: sections,
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeOutCubic,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: TextStyle(color: Colors.white, fontSize: 30.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Best: ${bestThresholdLabel(highThresholdLux)}',
                          style: TextStyle(color: chronoColor, fontSize: 15.sp, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2.h),
                        Text('Døgnscore', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.sp)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoTile(label: 'Kronotype', value: chronoLabel),
                _InfoTile(label: 'MEQ', value: widget.meqScore > 0 ? widget.meqScore.toString() : '–'),
                _InfoTile(label: 'rMEQ', value: widget.rmeqScore.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChronotypeColor(String type) {
    switch (type) {
      case 'definitely_morning': return Colors.blueAccent;
      case 'moderately_morning': return Colors.lightBlue;
      case 'neither': return Colors.grey;
      case 'moderately_evening': return Colors.orangeAccent;
      case 'definitely_evening': return Colors.deepOrange;
      default: return Colors.white60;
    }
  }

  String bestThresholdLabel(double threshold) =>
      threshold >= 500 ? 'Godt lys' : 'Optimal lys';

  String _getScoreLabel(double ratio) {
    if (ratio >= 0.7) return 'Fremragende';
    if (ratio >= 0.4) return 'Moderat';
    return 'Forbedring';
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
      SizedBox(height: 4.h),
      Text(value, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500)),
    ],
  );
}