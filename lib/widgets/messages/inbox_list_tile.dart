import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: generalBox,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(
            isUnread ? Icons.mark_email_unread : Icons.mark_email_read_outlined,
            color: isUnread ? Colors.white70 : Colors.white38,
          ),
          title: Text(
            subject,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(msg['sent_at']),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
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
