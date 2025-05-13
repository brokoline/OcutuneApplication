import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

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

      print('✅ Hentet tråd med ${msgs.length} beskeder');

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
      await _loadData(); // hent opdateret tråd
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: thread.length,
              itemBuilder: (context, index) {
                final msg = thread[index];
                final isMe = msg['sender_type'] == 'patient';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white : generalBox,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['message'],
                      style: TextStyle(color: isMe ? Colors.black : Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(color: generalBackground),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Svar',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: generalBox,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _replyController,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Tilføj et svar til din besked...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _sendReply,
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? isoDateTime) {
    try {
      if (isoDateTime == null || isoDateTime.isEmpty) return 'ukendt tidspunkt';
      final dt = DateTime.parse(isoDateTime);
      return 'd. ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          'kl. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'ukendt tidspunkt';
    }
  }
}
