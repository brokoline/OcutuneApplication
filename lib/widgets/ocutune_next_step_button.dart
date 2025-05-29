import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/colors.dart';

enum OcutuneButtonType {
  primary,
  secondary,
  floatingIcon,
}

class OcutuneButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final OcutuneButtonType type;

  const OcutuneButton({
    super.key,
    this.text = '',
    required this.onPressed,
    this.type = OcutuneButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final BorderSide? borderSide;

    switch (type) {
      case OcutuneButtonType.primary:
        backgroundColor = Colors.white;
        textColor = Colors.black;
        borderSide = null;
        break;
      case OcutuneButtonType.secondary:
        backgroundColor = darkGray;
        textColor = Colors.white38;
        borderSide = BorderSide(color: Colors.white70, width: 1.w);
        break;

      case OcutuneButtonType.floatingIcon:
        return SizedBox(
          width: 48.w,
          height: 48.w,
          child: FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: nextButton ,
            foregroundColor: Colors.black,
            onPressed: onPressed,
            elevation: 2,
            child: Icon(Icons.arrow_forward, size: 24.sp),
          ),
        );
    }

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: borderSide ?? BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
