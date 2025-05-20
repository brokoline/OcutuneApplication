import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread.dart';
import 'package:ocutune_light_logger/widgets/messages/reply_input.dart';
import 'package:ocutune_light_logger/widgets/confirm_dialog.dart';

class PatientMessageDetailScreen extends StatefulWidget {
  const PatientMessageDetailScreen({super.key});

  @override
  State<PatientMessageDetailScreen> createState() =>
      _PatientMessageDetailScreenState();
}

class _PatientMessageDetailScreenState
    extends State<PatientMessageDetailScreen> {
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
      final msgs = await api.ApiService.getMessageThreadById(threadId!);

      if (msgs.isEmpty) {
        print('❌ Tråden er tom – muligvis slettet');
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
      print('❌ Fejl ved hentning af tråd: $e');
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
      hasSentMessage = true;
      await _loadData(scrollToBottom: true); // scroll ned efter svar
    } catch (e) {
      print('❌ Kunne ikke sende svar: $e');
    }
  }

  Future<void> _deleteThread() async {
    if (threadId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Slet samtale?',
        message: 'Er du sikker på, at du vil slette hele tråden?',
        onConfirm: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      print('🔁 Sletter tråd med ID: $threadId');
      await api.ApiService.deleteThread(threadId!);
      hasDeletedThread = true;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('❌ Kunne ikke slette tråd: $e');
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
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white70),
          title: Text(
            original!['subject']?.isNotEmpty == true
                ? original!['subject']
                : 'Uden emne',
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
              tooltip: 'Slet tråd',
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
                    'Fra: ${original!['sender_name'] ?? 'Ukendt'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Til: ${original!['receiver_name'] ?? 'Ukendt'}',
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
