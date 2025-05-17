import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class OcutuneCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const OcutuneCard({
    super.key,
    required this.child,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.w),
        child: Container(
          padding: EdgeInsets.only(top: 22.h, bottom: 16.h, left: 24.w, right: 24.w),
          decoration: BoxDecoration(
            color: generalBox,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
