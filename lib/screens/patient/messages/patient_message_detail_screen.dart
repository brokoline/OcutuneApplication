import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread.dart';
import 'package:ocutune_light_logger/widgets/messages/reply_input.dart';
import 'package:flutter/widgets.dart' show PopScope, PopScopePagePopResult, PopDisposition;


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

      if (!mounted) return; // ← beskytter mod crash
      setState(() {
        original = msg;
        thread = msgs;
      });

      // Scroll til bunden bagefter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('❌ Fejl ved hentning af tråd: $e');
    }
  }


  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || threadId == null) return;

    // Luk tastaturet
    FocusScope.of(context).unfocus();

    try {
      await api.ApiService.sendPatientMessage(
        message: text,
        subject: 'Re: ${original!['subject'] ?? ''}',
        replyTo: threadId,
      );

      _replyController.clear();
      hasSentMessage = true; // brugt til at opdatere inbox bagefter
      await _loadData();
    } catch (e) {
      print('❌ Kunne ikke sende svar: $e');
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
        Navigator.pop(context, hasSentMessage);
        return false; // vi håndterer pop selv
      },
      // TODO  : Skal opgraderes da WillPopScope er deprecated, og jeg kan ikke finde en løsning
      child: Scaffold(
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
