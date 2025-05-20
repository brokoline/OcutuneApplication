import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread.dart';
import 'package:ocutune_light_logger/widgets/messages/reply_input.dart';
import 'package:ocutune_light_logger/widgets/confirm_dialog.dart';

class ClinicianMessageDetailScreen extends StatefulWidget {
  const ClinicianMessageDetailScreen({super.key});

  @override
  State<ClinicianMessageDetailScreen> createState() =>
      _ClinicianMessageDetailScreenState();
}

class _ClinicianMessageDetailScreenState
    extends State<ClinicianMessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> thread = [];
  Map<String, dynamic>? original;
  int? threadId;
  bool hasSentMessage = false;
  bool hasDeletedThread = false;
  bool hasMarkedAsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    threadId = ModalRoute.of(context)!.settings.arguments as int;
    _loadData();
  }

  Future<void> _loadData({bool scrollToBottom = true}) async {
    if (threadId == null) return;

    try {
      final msgs = await api.ApiService.getClinicianMessageThreadById(threadId!);

      if (msgs.isEmpty) {
        print('❌ Thread is empty - possibly deleted');
        if (mounted) Navigator.pop(context, true);
        return;
      }

      await api.ApiService.markThreadAsRead(threadId!);
      hasMarkedAsRead = true;

      if (!mounted) return;
      setState(() {
        thread = msgs;
        original = msgs.first;
      });

      if (scrollToBottom) {
        Future.delayed(const Duration(milliseconds: 100), () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              try {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              } catch (_) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              }
            }
          });
        });
      }

    } catch (e) {
      print('❌ Error loading thread: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || threadId == null) return;

    FocusScope.of(context).unfocus();

    try {
      await api.ApiService.sendClinicianMessage(
        message: text,
        subject: 'Re: ${original!['subject'] ?? ''}',
        replyTo: threadId,
      );

      _replyController.clear();
      hasSentMessage = true;
      await _loadData(scrollToBottom: true);
    } catch (e) {
      print('❌ Could not send reply: $e');
    }
  }

  Future<void> _deleteThread() async {
    if (threadId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete conversation?',
        message: 'Are you sure you want to delete this entire thread?',
        onConfirm: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      print('🔁 Deleting thread with ID: $threadId');
      await api.ApiService.deleteThread(threadId!);
      hasDeletedThread = true;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('❌ Could not delete thread: $e');
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (original == null || thread.isEmpty) {
      return Scaffold(
        backgroundColor: generalBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(
          context,
          hasSentMessage || hasDeletedThread || hasMarkedAsRead,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: generalBackground,
        appBar: AppBar(
          backgroundColor: generalBackground,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white70),
          title: Text(
            original!['subject']?.isNotEmpty == true
                ? original!['subject']
                : 'No subject',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteThread,
              tooltip: 'Delete thread',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${original!['sender_name'] ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To: ${original!['receiver_name'] ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MessageThread(
                messages: thread,
                scrollController: _scrollController,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(color: generalBackground),
              child: ReplyInput(
                controller: _replyController,
                onSend: _sendReply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}