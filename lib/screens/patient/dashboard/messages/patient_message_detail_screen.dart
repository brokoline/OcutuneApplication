import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class PatientMessageDetailScreen extends StatefulWidget {
  const PatientMessageDetailScreen({super.key});

  @override
  State<PatientMessageDetailScreen> createState() => _PatientMessageDetailScreenState();
}

class _PatientMessageDetailScreenState extends State<PatientMessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  Map<String, dynamic>? data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int messageId = ModalRoute.of(context)!.settings.arguments as int;
    ApiService.getMessageDetail(messageId).then((value) {
      setState(() => data = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
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
        title: const Text(
          'Beskeder',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beskedkort
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data!['subject'] ?? '(Uden emne)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fra: ${data!['sender']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sendt: ${_formatDateTime(data!['sent_at'])}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data!['message'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Svarsektion
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

            ElevatedButton.icon(
              onPressed: () {
                // TODO: Send svar via backend
                print('Svar sendt: ${_replyController.text}');
              },
              icon: const Icon(Icons.reply),
              label: const Text('Send svar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? input) {
    try {
      if (input == null || input.isEmpty) return 'ukendt tidspunkt';
      final dt = DateTime.parse(input);
      return 'D. ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          'Kl. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ Kunne ikke parse sent_at: $input');
      return 'ukendt tidspunkt';
    }
  }
}
