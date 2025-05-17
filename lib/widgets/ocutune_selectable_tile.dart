import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OcutuneSelectableTile extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const OcutuneSelectableTile({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.white : Colors.white24, width: 1.w),
          borderRadius: BorderRadius.circular(16.r),
          color: selected ? Colors.white10 : Colors.transparent,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}
