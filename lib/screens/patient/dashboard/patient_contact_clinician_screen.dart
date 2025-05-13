import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class PatientContactClinicianScreen extends StatefulWidget {
  const PatientContactClinicianScreen({super.key});

  @override
  State<PatientContactClinicianScreen> createState() => _PatientContactClinicianScreenState();
}

class _PatientContactClinicianScreenState extends State<PatientContactClinicianScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;
  bool _loadingMessages = true;
  int? patientId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadPatientAndMessages();
  }

  Future<void> _loadPatientAndMessages() async {
    final id = await AuthStorage.getUserId();
    if (id == null) return;

    try {
      final messages = await ApiService.getPatientMessages(id);
      setState(() {
        patientId = id;
        _messages = messages;
        _loadingMessages = false;
      });
    } catch (e) {
      print('💥 Fejl ved hentning af beskeder: $e');
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || patientId == null) return;

    setState(() => _sending = true);

    try {
      await ApiService.sendPatientMessage(
        patientId: patientId!,
        message: message,
      );

      _messageController.clear();

      // Hent opdateret beskedliste
      final messages = await ApiService.getPatientMessages(patientId!);
      setState(() {
        _messages = messages;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Besked sendt')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Fejl ved afsendelse')),
      );
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Kontakt din behandler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Samtalehistorik',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _loadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? const Center(
                child: Text(
                  'Ingen beskeder endnu...',
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender_type'] == 'patient';

                  return Align(
                    alignment:
                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white : generalBox,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg['message'],
                        style: TextStyle(
                          color: isMe ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Inputfelt
            Container(
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Skriv din besked her...',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sender...' : 'Send besked'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
