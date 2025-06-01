// lib/widgets/clinician_widgets/patient_light_data_widgets/light_data_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/colors.dart';
import '../../../../models/light_data_model.dart';

class LightDataCard extends StatelessWidget {
  /// We now accept a List<LightData> from the parent.
  final List<LightData> lightData;

  const LightDataCard({
    Key? key,
    required this.lightData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<LightData> data = lightData;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        collapsedBackgroundColor: generalBox,
        backgroundColor: generalBox,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        trailing: const Icon(Icons.expand_more, color: Colors.white),
        title: Text(
          'Lysdata',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          if (data.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Ingen lysdata tilgængelig',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: data.map((d) {
                  final iconColor = d.actionRequired ? Colors.redAccent : Colors.white;
                  final hour = d.capturedAt.hour.toString().padLeft(2, '0');
                  final minute = d.capturedAt.minute.toString().padLeft(2, '0');
                  final timeString = '$hour:$minute';

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 18.w,
                          color: iconColor,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            '$timeString  –  ${d.lightType}  •  Lux: ${d.illuminance}  •  EDI: ${d.melanopicEdi}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
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
