import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../models/light_data_model.dart';
import '../../../../theme/colors.dart';

class LightLatestEventsList extends StatelessWidget {
  final List<LightData> lightData;

  const LightLatestEventsList({super.key, required this.lightData});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: generalBox,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seneste målinger", style: TextStyle(color: Colors.white, fontSize: 16.sp)),
            SizedBox(height: 12.h),
            ...lightData.take(10).map((d) => Padding(
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
                      DateFormat('HH:mm').format(d.capturedAt) +
                          " • Lux: ${d.illuminance}  • EDI: ${d.melanopicEdi}",
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  )
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
