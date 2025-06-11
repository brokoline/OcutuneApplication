import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../controller/chronotype_controller.dart';
import '../../../services/processing/light_data_processing.dart';
import '../../../../models/light_data_model.dart';

class LightRecommendationsCard extends StatelessWidget {
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

  List<String> _buildRecommendations() {
    if (showChronotype) {
      final chrono = ChronotypeManager(rmeqScore);
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
      return LightDataProcessing(rMEQ: rmeqScore)
          .generateAdvancedRecommendations(
        data: lightData,
        rMEQ: rmeqScore,
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

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          collapsedBackgroundColor: generalBox,
          backgroundColor: generalBox,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          trailing: Icon(Icons.expand_more, color: Colors.white70),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                  padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _recIcon(r),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
