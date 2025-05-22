import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class InboxListTile extends StatefulWidget {
  final Map<String, dynamic> msg;
  final VoidCallback onTap;

  const InboxListTile({super.key, required this.msg, required this.onTap});

  @override
  State<InboxListTile> createState() => _InboxListTileState();
}

class _InboxListTileState extends State<InboxListTile> {
  String? label;
  bool? isSender;
  bool? isUnread;

  @override
  void initState() {
    super.initState();
    Future.microtask(_determineState);
  }

  Future<void> _determineState() async {
    try {
      final jwt = await AuthStorage.getTokenPayload();
      final currentUserId = jwt['id'];

      final sender = widget.msg['sender_id'];
      final receiver = widget.msg['receiver_id'];

      isSender = sender == currentUserId;
      isUnread = widget.msg['read'] == 0;

      final name = isSender!
          ? widget.msg['receiver_name'] ?? 'Ukendt'
          : widget.msg['sender_name'] ?? 'Ukendt';

      if (mounted) {
        setState(() {
          label = isSender! ? 'Til: $name' : 'Fra: $name';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          label = 'Ukendt';
          isSender = false;
          isUnread = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        child: Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: generalBox,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }

    final subject = widget.msg['subject']?.toString().trim().isNotEmpty == true
        ? widget.msg['subject']
        : '(Uden emne)';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Material(
        color: generalBox,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.r),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusIcon(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight:
                          (isUnread! && !isSender!) ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        label!,
                        style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDate(widget.msg['sent_at']),
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 Her definerer vi ikonlogikken med 3 tilstande
  Widget _buildStatusIcon() {
    if (isSender == null || isUnread == null) {
      return const Icon(Icons.mail_outline, color: Colors.grey);
    }

    if (!isUnread!) {
      return const Icon(Icons.mark_email_read_outlined, color: Colors.grey);
    }

    if (!isSender!) {
      return const Icon(Icons.mark_email_unread, color: Colors.blueGrey);
    }

    // Hvis afsender og besked stadig ulæst af modtager → special-ikon
    return Stack(
      alignment: Alignment.center,
      children: const [
        Icon(Icons.email_outlined, color: Colors.grey),
        Positioned(
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

  String _formatDate(String rawDate) {
    try {
      final dt = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .parseUtc(rawDate)
          .toLocal();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);

      final day = (msgDay == today)
          ? 'I dag'
          : (msgDay == today.subtract(const Duration(days: 1)))
          ? 'I går'
          : DateFormat('dd.MM').format(dt);

      final time = DateFormat('HH:mm').format(dt);
      return '$day • $time';
    } catch (_) {
      return '';
    }
  }
}
