// lib/widgets/clinician_widgets/patient_light_data_widgets/light_latest_events_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../models/light_data_model.dart';

class LightLatestEventsList extends StatelessWidget {
  /// Vi modtager her 10 seneste LightData som parameter
  final List<LightData> lightData;

  const LightLatestEventsList({
    Key? key,
    required this.lightData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: generalBox,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seneste målinger", style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
            SizedBox(height: 12.h),
            ...lightData.take(10).map((d) {
              final timeString = DateFormat('HH:mm').format(d.capturedAt.toLocal());
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  children: [
                    Icon(
                      d.actionRequired ? Icons.warning : Icons.wb_sunny,
                      color: d.actionRequired ? Colors.redAccent : Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "$timeString  •  Lux: ${d.illuminance}  •  EDI: ${d.melanopicEdi}",
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
