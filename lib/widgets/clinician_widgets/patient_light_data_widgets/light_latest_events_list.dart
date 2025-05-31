// lib/widgets/clinician_widgets/patient_light_data_widgets/light_latest_events_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../models/light_data_model.dart';
import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';

class LightLatestEventsList extends StatelessWidget {
  const LightLatestEventsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Hent PatientDetailViewModel
    final vm = context.watch<PatientDetailViewModel>();

    // 2) Hent de rå lysdata, og tag de 10 seneste
    final List<LightData> lightData = vm.rawLightData.take(10).toList();

    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seneste målinger",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            if (lightData.isEmpty)
              Text(
                'Ingen lysdata tilgængelig',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              )
            else
              ...lightData.map((d) {
                final iconData = d.actionRequired ? Icons.warning : Icons.wb_sunny;
                final iconColor = d.actionRequired ? Colors.redAccent : Colors.white;
                final timeStr = DateFormat('HH:mm').format(d.capturedAt);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: Row(
                    children: [
                      Icon(iconData, color: iconColor, size: 16.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "$timeStr  •  Lux: ${d.illuminance}  •  EDI: ${d.melanopicEdi}",
                          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                        ),
                      ),
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
