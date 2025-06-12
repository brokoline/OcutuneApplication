// lib/widgets/clinician_widgets/patient_light_data_widgets/clinician_recommendation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ClinicianRecommendationCard extends StatelessWidget {
  final List<String> recommendations;

  const ClinicianRecommendationCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hvis der ikke er nogen anbefalinger, vis en standardtekst
          if (recommendations.isEmpty)
            Center(
              child: Text(
                "Ingen anbefalinger i øjeblikket",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
          // Vis hver anbefaling som en punktopstilling
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations.map((rec) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bullet-punkt
                      Container(
                        width: 6.w,
                        height: 6.w,
                        margin: EdgeInsets.only(top: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Tekst
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
