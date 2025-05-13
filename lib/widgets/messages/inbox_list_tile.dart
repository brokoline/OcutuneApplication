import 'package:flutter/material.dart';
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
    final isUnread = msg['read'] == false;
    final subject = msg['subject']?.isNotEmpty == true ? msg['subject'] : '(Uden emne)';

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
            color: isUnread ? Colors.white : Colors.white38,
          ),
          title: Text(
            subject,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Fra: ${msg['sender']}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            _formatDate(msg['sent_at']),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatDate(String isoDateTime) {
    final dt = DateTime.tryParse(isoDateTime);
    if (dt == null) return '';
    final date = 'D. ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final time = 'Kl. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date\n$time';
  }
}
