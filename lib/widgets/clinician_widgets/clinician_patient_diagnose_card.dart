import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/colors.dart';
import '../../../models/diagnose_model.dart';

class DiagnosisCard extends StatelessWidget {
  final List<Diagnosis> diagnoses;

  const DiagnosisCard({super.key, required this.diagnoses});

  @override
  Widget build(BuildContext context) {
    if (diagnoses.isEmpty) {
      return Text(
        'Ingen diagnoser registreret',
        style: TextStyle(color: Colors.white70),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        color: generalBox,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: diagnoses.map((d) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                '• ${d.diagnosis} (${d.code})',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}
