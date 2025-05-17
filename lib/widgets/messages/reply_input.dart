import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ReplyInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Svar',
          style: TextStyle(color: Colors.white70, fontSize: 16.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: generalBox,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white24, width: 1.w),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Tilføj et svar til din besked...',
              hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: onSend,
            icon: Icon(Icons.reply, size: 18.sp),
            label: Text('Send', style: TextStyle(fontSize: 14.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
