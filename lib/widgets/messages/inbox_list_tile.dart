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
    final isFromMe = msg['sender_type'] == 'patient';
    final isUnread = msg['read'] == 0;
    final subject = msg['subject']?.toString().trim().isNotEmpty == true
        ? msg['subject']
        : '(Uden emne)';

    final label = isFromMe
        ? 'Til: ${msg['display_name'] ?? 'Ukendt'}'
        : 'Fra: ${msg['sender_name'] ?? 'Ukendt'}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Material(
        color: generalBox,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusIcon(isFromMe, isUnread),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: (isUnread && !isFromMe)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDate(msg['sent_at']),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isFromMe, bool isUnread) {
    if (!isUnread) {
      return const Icon(Icons.mark_email_read_outlined, color: Colors.grey);
    }

    if (!isFromMe) {
      return const Icon(Icons.mark_email_unread, color: Colors.blueGrey);
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.email_outlined, color: Colors.grey),
          const Positioned(
            bottom: -2,
            right: -2,
            child: Icon(
              Icons.access_time,
              size: 16,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }
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
