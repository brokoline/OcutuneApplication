import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread.dart';
import 'package:ocutune_light_logger/widgets/messages/reply_input.dart';
import 'package:ocutune_light_logger/widgets/confirm_dialog.dart';

class PatientMessageDetailScreen extends StatefulWidget {
  const PatientMessageDetailScreen({super.key, this.onThreadDeleted});

  final Function(int)? onThreadDeleted;

  @override
  State<PatientMessageDetailScreen> createState() =>
      _PatientMessageDetailScreenState();
}

class _PatientMessageDetailScreenState extends State<PatientMessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> thread = [];
  Map<String, dynamic>? original;
  int? threadId;
  bool hasSentMessage = false;
  bool hasDeletedThread = false;
  bool hasMarkedAsRead = false;
  bool _isDeleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    threadId = ModalRoute.of(context)!.settings.arguments as int;
    _loadData();
  }

  Future<void> _loadData({bool scrollToBottom = true}) async {
    if (threadId == null) return;

    try {
      final msgs = await api.ApiService.getMessageThreadById(threadId!);

      if (msgs.isEmpty) {
        debugPrint('❌ Thread is empty - possibly deleted');
        if (mounted) {
          Navigator.pop(context, true);
          if (widget.onThreadDeleted != null) {
            widget.onThreadDeleted!(threadId!);
          }
        }
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
      }
    } catch (e) {
      debugPrint('❌ Error loading thread: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || threadId == null) return;

    FocusScope.of(context).unfocus();

    try {
      await api.ApiService.sendPatientMessage(
        message: text,
        subject: 'Re: ${original!['subject'] ?? ''}',
        replyTo: threadId,
      );

      _replyController.clear();
      setState(() => hasSentMessage = true);
      await _loadData(scrollToBottom: true);
    } catch (e) {
      debugPrint('❌ Could not send reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send reply: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteThread() async {
    if (threadId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete conversation?',
        message: 'Are you sure you want to delete the entire thread?',
        onConfirm: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🔁 Deleting thread with ID: $threadId');
      setState(() => _isDeleting = true);

      await api.ApiService.deleteThread(threadId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread deleted')),
        );

        Navigator.pop(context, true);
        if (widget.onThreadDeleted != null) {
          widget.onThreadDeleted!(threadId!);
        }
      }
    } catch (e) {
      debugPrint('❌ Could not delete thread: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete thread: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(
            context,
            hasSentMessage || hasDeletedThread || hasMarkedAsRead,
          );
        }
      },
      child: Scaffold(
        backgroundColor: generalBackground,
        appBar: AppBar(
          backgroundColor: generalBackground,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
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
              icon: _isDeleting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _deleteThread,
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