import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget that displays personal and detailed light recommendations,
/// with the detailed DLMO section rendered as a simple dropdown.
class CustomerLightRecommendationsCard extends StatelessWidget {
  /// Personal, high-level recommendations (e.g. "Your light rhythm looks fine...").
  final List<String> personalRecommendations;

  /// Detailed recommendations (e.g. "Kronotype: neither", "DLMO: 21:49").
  final List<String> detailRecommendations;

  const CustomerLightRecommendationsCard({
    Key? key,
    this.personalRecommendations = const [],
    this.detailRecommendations = const [],
  }) : super(key: key);

  /// Maps a recommendation string to an appropriate icon.
  Widget _detailIcon(String rec) {
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
    return Icon(Icons.lightbulb_outline, color: Colors.white70, size: 20.sp);
  }

  @override
  Widget build(BuildContext context) {
    final bool showPersonal = personalRecommendations.isNotEmpty;
    final bool showDetail = detailRecommendations.isNotEmpty;

    // If no recommendations at all
    if (!showPersonal && !showDetail) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'Ingen anbefalinger tilgængelige',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- DLMO analyse og anbefalinger som dropdown ----
        if (showDetail)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
            decoration: BoxDecoration(color: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,

              // Header tekst
              title: Text(
                'DLMO analyse og anbefalinger',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Dropdown-ikon (roterer automatisk når åbnet)
              trailing: Icon(
                Icons.expand_more,
                color: Colors.white70,
                size: 24.sp,
              ),

              // Paddings for children
              childrenPadding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),

              // Selve rekommandationerne
              children: detailRecommendations.map((r) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  horizontalTitleGap: 12.w,
                  leading: _detailIcon(r),
                  title: Text(
                    r,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // ---- Personlige anbefalinger ----
        if (showPersonal)
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 8.h, left: 2.w, right: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Personlige anbefalinger',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                ...personalRecommendations.map((r) {
                  final bool isFine = r.trim().toLowerCase().contains('fin ud i denne periode');
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isFine ? Icons.check_circle : Icons.lightbulb_outline,
                          color: isFine ? Colors.greenAccent : Colors.white70,
                          size: 20.sp,
                        ),
                        SizedBox(width: 14.w),
                        Flexible(
                          child: Text(
                            r,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
