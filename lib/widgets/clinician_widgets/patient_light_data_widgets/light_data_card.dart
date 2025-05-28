import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/light_data_model.dart';
import '../../../../theme/colors.dart';

class LightDataCard extends StatelessWidget {
  final List<LightData> lightData;

  const LightDataCard({super.key, required this.lightData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        collapsedBackgroundColor: generalBox,
        backgroundColor: generalBox,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        trailing: Icon(Icons.expand_more, color: Colors.white),
        title: Text(
          'Lysdata',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        children: [
          if (lightData.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text('Ingen lysdata tilgængelig', style: TextStyle(color: Colors.white70)),
            )
          else
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: lightData.map((d) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 18.w, color: d.actionRequired ? Colors.redAccent : Colors.white),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '${d.capturedAt.hour}:${d.capturedAt.minute.toString().padLeft(2, '0')} - ${d.lightType} • Lux: ${d.illuminance} • EDI: ${d.melanopicEdi}',
                          style: TextStyle(color: Colors.white, fontSize: 13.sp),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
