// lib/widgets/clinician_widgets/patient_light_data_widgets/light_latest_events_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../models/light_data_model.dart';
import '../../../../theme/colors.dart';

class LightLatestEventsList extends StatelessWidget {
  /// We now accept a List<LightData> from the parent.
  final List<LightData> lightData;

  const LightLatestEventsList({
    super.key,
    required this.lightData,
  });

  @override
  Widget build(BuildContext context) {
    final List<LightData> data = lightData;

    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seneste målinger",
                style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
            SizedBox(height: 12.h),
            ...data.take(10).map((d) {
              final icon = d.actionRequired
                  ? Icons.warning
                  : Icons.wb_sunny;
              final iconColor = d.actionRequired
                  ? Colors.redAccent
                  : Colors.white;

              final ts = DateFormat('HH:mm').format(d.capturedAt);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 16.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "$ts  •  Lux: ${d.illuminance}  •  EDI: ${d.melanopicEdi}",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
