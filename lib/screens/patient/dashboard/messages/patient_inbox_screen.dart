import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class PatientInboxScreen extends StatefulWidget {
  const PatientInboxScreen({super.key});

  @override
  State<PatientInboxScreen> createState() => _PatientInboxScreenState();
}

class _PatientInboxScreenState extends State<PatientInboxScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final id = await AuthStorage.getUserId();
    if (id == null) return;

    try {
      final msgs = await ApiService.getInboxMessages(id);
      setState(() {
        _messages = msgs;
        _loading = false;
      });
    } catch (e) {
      print('❌ Fejl ved hentning af indbakke: $e');
      setState(() => _loading = false);
    }
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
          'Indbakke',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
              child: Text(
                'Ingen beskeder endnu.',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUnread = msg['read'] == false;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: generalBox,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: isUnread
                          ? const Icon(Icons.mark_email_unread, color: Colors.white)
                          : const Icon(Icons.mark_email_read_outlined, color: Colors.white38),
                      title: Text(
                        msg['subject']?.isNotEmpty == true ? msg['subject'] : '(Uden emne)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Fra: ${msg['sender']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        _formatDate(msg['sent_at']),
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/patient/message_detail',
                          arguments: msg['id'],
                        ).then((_) => _loadMessages()); // genindlæs efter åbning
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/patient/new_message');
              },
              icon: const Icon(Icons.add),
              label: const Text('Ny besked'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDateTime) {
    final dt = DateTime.tryParse(isoDateTime);
    if (dt == null) return '';
    final date = 'D. ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final time = 'Kl. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date\n$time';
  }
}
