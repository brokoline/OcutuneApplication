import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerLightDetailScreen extends StatelessWidget {
  const CustomerLightDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiserer ScreenUtil
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              'Her kan du se dybdegående lys-data, grafer mv.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
