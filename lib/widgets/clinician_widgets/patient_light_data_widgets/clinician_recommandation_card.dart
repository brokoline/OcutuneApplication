import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/colors.dart';

/// En sammenklappelig boks, der matcher stilen fra Patientoplysninger og Registrerede aktiviteter.
class ClinicianRecommendationCard extends StatelessWidget {
  final List<String> recommendations;

  const ClinicianRecommendationCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        collapsedBackgroundColor: generalBox,
        backgroundColor: generalBox,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r)),
        trailing: Icon(Icons.expand_more, color: Colors.white70),
        title: Text(
          'Analyse af lysmålinger',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: recommendations.isEmpty
                ? Center(
              child: Text(
                'Ingen anbefalinger i øjeblikket',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations.map((rec) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
          ),
        ],
      ),
    );
  }
}