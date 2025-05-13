import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class PatientContactClinicianScreen extends StatefulWidget {
  const PatientContactClinicianScreen({super.key});

  @override
  State<PatientContactClinicianScreen> createState() => _PatientContactClinicianScreenState();
}

class _PatientContactClinicianScreenState extends State<PatientContactClinicianScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  void _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) return;

    setState(() => _sending = true);

    // Simulerer send
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _sending = false;
      _messageController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Besked sendt til din behandler')),
    );
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Skriv en besked',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

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
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Skriv din besked her...',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),

            const Spacer(),

            // Send-knap
            ElevatedButton.icon(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
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
