import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/diagnose_model.dart';
import '../../../theme/colors.dart';

class DiagnosisCard extends StatelessWidget {
  final List<Diagnosis> diagnoses;

  const DiagnosisCard({super.key, required this.diagnoses});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          collapsedBackgroundColor: generalBox,
          backgroundColor: generalBox,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          trailing: Icon(Icons.expand_more, color: Colors.white),
          title: Text(
            'Diagnoser',
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: diagnoses.isEmpty
                  ? Text('Ingen diagnoser registreret', style: TextStyle(color: Colors.white70))
                  : Column(
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
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
