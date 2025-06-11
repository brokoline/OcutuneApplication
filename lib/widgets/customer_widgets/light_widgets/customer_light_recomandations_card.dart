import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerLightRecommendationsCard extends StatelessWidget {
  final List<String> personalRecommendations;
  final List<String> detailRecommendations;

  const CustomerLightRecommendationsCard({
    super.key,
    this.personalRecommendations = const [],
    this.detailRecommendations = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bool showPersonal = personalRecommendations.isNotEmpty;
    final bool showDetail = detailRecommendations.isNotEmpty;

    // Check for OK/tjek besked
    bool isAllFineMsg = showPersonal &&
        personalRecommendations.length == 1 &&
        personalRecommendations.first.trim().toLowerCase().contains("fin ud i denne periode");

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Detail/døgnrytme anbefalinger (med kort) ----
        if (showDetail)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Døgnrytme & lys-anbefalinger",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...detailRecommendations.map((r) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.white70, size: 18.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),

        // ---- Personlige anbefalinger (uden card) ----
        if (showPersonal)
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 8.h, left: 2.w, right: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Personlige anbefalinger",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                ...personalRecommendations.map((r) {
                  final bool isFine = r.trim().toLowerCase().contains("fin ud i denne periode");
                  return Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Centrer hele raden
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isFine ? Icons.check_circle : Icons.lightbulb_outline,
                          color: isFine ? Colors.greenAccent : Colors.white70,
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        // Brug Flexible her for sikkerheds skyld, hvis teksten er lang:
                        Flexible(
                          child: Text(
                            r,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                            textAlign: TextAlign.center, // Centrér teksten
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
