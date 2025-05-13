import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread.dart';
import 'package:ocutune_light_logger/widgets/messages/reply_input.dart';

class PatientMessageDetailScreen extends StatefulWidget {
  const PatientMessageDetailScreen({super.key});

  @override
  State<PatientMessageDetailScreen> createState() => _PatientMessageDetailScreenState();
}

class _PatientMessageDetailScreenState extends State<PatientMessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  List<Map<String, dynamic>> thread = [];
  Map<String, dynamic>? original;
  int? patientId;
  int? threadId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    threadId = ModalRoute.of(context)!.settings.arguments as int;
    _loadData();
  }

  Future<void> _loadData() async {
    patientId = await AuthStorage.getUserId();
    if (patientId == null || threadId == null) return;

    try {
      final msg = await ApiService.getMessageDetail(threadId!);
      final msgs = await ApiService.getMessageThreadById(threadId!);
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
    if (text.isEmpty || patientId == null || threadId == null) return;

    try {
      await ApiService.sendPatientMessage(
        patientId: patientId!,
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
          original!['subject']?.isNotEmpty == true ? original!['subject'] : 'Uden emne',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
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
