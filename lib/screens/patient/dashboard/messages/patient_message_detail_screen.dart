import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread.dart';
import 'package:ocutune_light_logger/widgets/messages/reply_input.dart';

class PatientMessageDetailScreen extends StatefulWidget {
  const PatientMessageDetailScreen({super.key});

  @override
  State<PatientMessageDetailScreen> createState() =>
      _PatientMessageDetailScreenState();
}

class _PatientMessageDetailScreenState
    extends State<PatientMessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  List<Map<String, dynamic>> thread = [];
  Map<String, dynamic>? original;
  int? threadId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    threadId = ModalRoute.of(context)!.settings.arguments as int;
    _loadData();
  }

  Future<void> _loadData() async {
    if (threadId == null) return;

    try {
      final msg = await api.ApiService.getMessageDetail(threadId!);
      final msgs = await api.ApiService.getMessageThreadById(threadId!);
      setState(() {
        original = msg;
        thread = msgs;
      });
    } catch (e) {
      print('❌ Fejl ved hentning af tråd: $e');
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || threadId == null) return;

    try {
      await api.ApiService.sendPatientMessage(
        message: text,
        subject: 'Re: ${original!['subject'] ?? ''}',
        replyTo: threadId,
      );

      _replyController.clear();
      await _loadData(); // genindlæs tråd
    } catch (e) {
      print('❌ Kunne ikke sende svar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (original == null || thread.isEmpty) {
      return Scaffold(
        backgroundColor: generalBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          original!['subject']?.isNotEmpty == true
              ? original!['subject']
              : 'Uden emne',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            child: MessageThread(messages: thread),
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
    );
  }
}
