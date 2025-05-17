import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewMessageForm extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final bool sending;
  final String sendButtonLabel;

  const NewMessageForm({
    super.key,
    required this.subjectController,
    required this.messageController,
    required this.onSend,
    this.sending = false,
    this.sendButtonLabel = 'Send besked',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: subjectController,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'Emne',
            labelStyle: TextStyle(color: Colors.white70, fontSize: 14.sp),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: TextField(
            controller: messageController,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: 'Skriv din besked...',
              hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: sending ? null : onSend,
            icon: sending
                ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: const CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
                : Icon(Icons.send, size: 20.sp),
            label: Text(
              sending ? 'Sender...' : sendButtonLabel,
              style: TextStyle(fontSize: 14.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: Size.fromHeight(48.h),
              textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
            ),
          ),
        ),
      ],
    );
  }
}
