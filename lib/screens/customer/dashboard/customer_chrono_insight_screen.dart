import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerChronoInsightScreen extends StatelessWidget {
  const CustomerChronoInsightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiserer ScreenUtil
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nørdeside – detaljeret baggrundsinfo:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '- Videnskabelige referencer om søvn & lys\n'
                    '- Sensor-logs og rådata-graf\n'
                    '- Teknik-dokumentation (API-specifikationer)\n'
                    '- … og meget mere',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
