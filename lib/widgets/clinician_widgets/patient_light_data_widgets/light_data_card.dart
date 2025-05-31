// lib/widgets/clinician_widgets/patient_light_data_widgets/light_data_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../theme/colors.dart';
import '../../../../models/light_data_model.dart';
import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';

class LightDataCard extends StatelessWidget {
  const LightDataCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Hent PatientDetailViewModel via Provider
    final vm = context.watch<PatientDetailViewModel>();

    // 2) Hent rå lysdata‐listen (kan være tom)
    final List<LightData> lightData = vm.rawLightData;

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
          // 3) Hvis listen er tom, vis en “ingen data”–tekst
          if (lightData.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Ingen lysdata tilgængelig',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            )
          // 4) Ellers: Gennemløb alle LightData‐poster og vis dem i en kolonne
          else
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: lightData.map((d) {
                  // Skift ikon‐farve hvis der kræves handling (actionRequired)
                  final iconColor = d.actionRequired ? Colors.redAccent : Colors.white;

                  // Formater “HH:mm”
                  final timeString = d.capturedAt.hour.toString().padLeft(2, '0') +
                      ':' +
                      d.capturedAt.minute.toString().padLeft(2, '0');

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
