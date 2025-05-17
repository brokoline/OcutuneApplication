import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class InboxListTile extends StatelessWidget {
  final Map<String, dynamic> msg;
  final VoidCallback onTap;

  const InboxListTile({
    super.key,
    required this.msg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = msg['read'] == 0;
    final subject = msg['subject']?.isNotEmpty == true ? msg['subject'] : '(Uden emne)';
    final isFromMe = msg['sender_type'] == 'patient';

    final label = isFromMe
        ? 'Til: ${msg['receiver_name'] ?? 'Ukendt'}'
        : 'Fra: ${msg['sender_name'] ?? 'Ukendt'}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: generalBox,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white24, width: 1.w),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          leading: Icon(
            isUnread ? Icons.mark_email_unread : Icons.mark_email_read_outlined,
            color: isUnread ? Colors.white70 : Colors.white38,
            size: 24.sp,
          ),
          title: Text(
            subject,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
          subtitle: Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(msg['sent_at']),
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .parseUtc(rawDate)
          .toLocal();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(dt.year, dt.month, dt.day);

      String dayPart;
      if (messageDay == today) {
        dayPart = 'I dag';
      } else if (messageDay == today.subtract(const Duration(days: 1))) {
        dayPart = 'I går';
      } else {
        dayPart = DateFormat('dd.MM').format(dt);
      }

      final timePart = DateFormat('HH:mm').format(dt);
      return '$dayPart • $timePart';
    } catch (_) {
      return '';
    }
  }
}
