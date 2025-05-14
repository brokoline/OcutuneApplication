import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';

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
    try {
      final msgs = await api.ApiService.getInboxMessages();
      final rootMessages = msgs.where((msg) => msg['id'] == msg['thread_id']).toList();

      setState(() {
        _messages = rootMessages;
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
                return InboxListTile(
                  msg: _messages[index],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/patient/message_detail',
                      arguments: _messages[index]['id'],
                    ).then((_) => _loadMessages());
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/patient/new_message')
                    .then((_) => _loadMessages());
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
}
