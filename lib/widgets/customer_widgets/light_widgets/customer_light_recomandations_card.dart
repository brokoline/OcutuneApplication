import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomerLightRecommendationsCard extends StatelessWidget {
  final List<String> personalRecommendations;
  final List<String> detailRecommendations;

  const CustomerLightRecommendationsCard({
    super.key,
    this.personalRecommendations = const [],
    this.detailRecommendations = const [],
  });

  // --------- Mapping detail recommendations to icons/colors ----------
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
    // Default:
    return Icon(Icons.lightbulb_outline, color: Colors.white70, size: 20.sp);
  }

  @override
  Widget build(BuildContext context) {
    final bool showPersonal = personalRecommendations.isNotEmpty;
    final bool showDetail = detailRecommendations.isNotEmpty;

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
        // ---- Døgnrytme/kronotype anbefalinger ----
        if (showDetail)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Kronotype & døgnrytme-anbefalinger",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                ...detailRecommendations.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _detailIcon(r),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

        // ---- Personlige anbefalinger (centreret header + tekst) ----
        if (showPersonal)
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 8.h, left: 2.w, right: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Personlige anbefalinger",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                ...personalRecommendations.map((r) {
                  final bool isFine = r.trim().toLowerCase().contains("fin ud i denne periode");
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
