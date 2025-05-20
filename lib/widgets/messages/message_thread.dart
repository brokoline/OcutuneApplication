import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/widgets/messages/message_bubble.dart';

class MessageThread extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController? scrollController;

  const MessageThread({
    super.key,
    required this.messages,
    this.scrollController,
  });

  @override
  State<MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends State<MessageThread> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant MessageThread oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      // ny besked tilføjet – scroll til bund
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      padding: EdgeInsets.all(16.w),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final msg = widget.messages[index];
        final isMe = msg['sender_type'] == 'patient';
        final time = _formatDateTime(msg['sent_at']);

        return Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MessageBubble(
              message: msg['message'],
              isMe: isMe,
            ),
            SizedBox(height: 4.h),
            Text(
              time,
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
            SizedBox(height: 12.h),
          ],
        );
      },
    );
  }

  String _formatDateTime(String rawDate) {
    try {
      final dt = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .parseUtc(rawDate)
          .toLocal();
      return DateFormat('dd.MM.yyyy • HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
