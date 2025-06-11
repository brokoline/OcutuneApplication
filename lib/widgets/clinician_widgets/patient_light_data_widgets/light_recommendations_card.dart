import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../controller/chronotype_controller.dart';
import '../../../services/processing/light_data_processing.dart';
import '../../../../models/light_data_model.dart';

class LightRecommendationsCard extends StatefulWidget {
  final String title;
  final int rmeqScore;
  final List<LightData> lightData;
  final bool showChronotype;
  final bool initiallyExpanded;

  const LightRecommendationsCard({
    super.key,
    required this.title,
    required this.rmeqScore,
    required this.lightData,
    this.showChronotype = false,
    this.initiallyExpanded = false,
  });

  @override
  State<LightRecommendationsCard> createState() => _LightRecommendationsCardState();
}

class _LightRecommendationsCardState extends State<LightRecommendationsCard> {
  late bool expanded;
  bool hovering = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  List<String> _buildRecommendations() {
    if (widget.showChronotype) {
      final chrono = ChronotypeManager(widget.rmeqScore);
      final chronoLabel = chrono.getChronotypeLabel();
      final timeMap = chrono.getRecommendedTimes();
      final fmt = DateFormat('HH:mm');
      return [
        "Kronotype: $chronoLabel",
        "DLMO (Dim Light Melatonin Onset): ${fmt.format(timeMap['dlmo']!)}",
        "Opvågning (DLMO + 10 timer): ${fmt.format(timeMap['wake_time']!)}",
        "Sengetid (DLMO + 2 timer): ${fmt.format(timeMap['sleep_start']!)}",
        "Light-boost start: ${fmt.format(timeMap['lightboost_start']!)}",
        "Light-boost slut: ${fmt.format(timeMap['lightboost_end']!)}",
      ];
    } else {
      return LightDataProcessing(rMEQ: widget.rmeqScore)
          .generateAdvancedRecommendations(
        data: widget.lightData,
        rMEQ: widget.rmeqScore,
      );
    }
  }

  Widget _recIcon(String rec) {
    if (rec.startsWith("Kronotype")) {
      return Icon(Icons.account_circle, color: Colors.lightBlue[200], size: 20.sp);
    }
    if (rec.startsWith("DLMO")) {
      return Icon(Icons.nightlight_round, color: Colors.purple[200], size: 20.sp);
    }
    if (rec.startsWith("Opvågning")) {
      return Icon(Icons.wb_sunny, color: Colors.yellow[600], size: 22.sp);
    }
    if (rec.startsWith("Sengetid")) {
      return Icon(Icons.bed, color: Colors.indigo[100], size: 20.sp);
    }
    if (rec.toLowerCase().contains("light-boost start")) {
      return Icon(Icons.lightbulb, color: Colors.amberAccent[400], size: 22.sp);
    }
    if (rec.toLowerCase().contains("light-boost slut")) {
      return Icon(Icons.nights_stay, color: Colors.blueAccent[200], size: 22.sp);
    }
    // Default:
    return Icon(Icons.lightbulb_outline, color: Colors.white70, size: 20.sp);
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _buildRecommendations();

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: generalBox,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: hovering ? Colors.white24 : Colors.transparent,
            width: 1.1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => expanded = !expanded),
                splashColor: Colors.white12,
                highlightColor: Colors.white10,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            widget.title,
                            style: TextStyle(
                                color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.w600)
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: expanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                          size: 30.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: Container(),
                secondChild: Padding(
                  padding: EdgeInsets.only(
                    left: 18.w, right: 18.w, bottom: 14.h,
                  ),
                  child: recommendations.isEmpty
                      ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      "Ingen anbefalinger tilgængelige",
                      style: TextStyle(color: Colors.white54, fontSize: 15.sp),
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recommendations.map((r) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _recIcon(r),
                            SizedBox(width: 13.w),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ]
                      ),
                    )).toList(),
                  ),
                ),
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
