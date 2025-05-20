import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';
import 'dart:io'; // for HttpDate

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
      final jwt = await AuthStorage.getTokenPayload();
      final currentUserId = jwt['id'];

      final msgs = await api.ApiService.getInboxMessages();
      final Map<int, List<Map<String, dynamic>>> grouped = {};

      // Gruppér beskeder pr. thread_id
      for (var msg in msgs) {
        final threadId = msg['thread_id'];
        grouped.putIfAbsent(threadId, () => []).add(msg);
      }

      final List<Map<String, dynamic>> threads = [];

      for (var threadMsgs in grouped.values) {
        // Sortér: nyeste først
        threadMsgs.sort((a, b) =>
            HttpDate.parse(b['sent_at']).compareTo(HttpDate.parse(a['sent_at'])));

        final newest = threadMsgs.first;
        final oldest = threadMsgs.last;

        // Vis navn på kliniker (baseret på første besked i tråden)
        final displayName = oldest['sender_id'] == currentUserId
            ? oldest['receiver_name']
            : oldest['sender_name'];

        threads.add({
          ...newest,
          'display_name': displayName,
        });
      }

      // Sortér tråde efter seneste besked
      threads.sort((a, b) =>
          HttpDate.parse(b['sent_at']).compareTo(HttpDate.parse(a['sent_at'])));

      setState(() {
        _messages = threads;
        _loading = false;
      });
    } catch (e) {
      print('❌ Fejl ved hentning af indbakke: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: generalBackground,
        appBar: AppBar(
          backgroundColor: generalBackground,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white70),
          title: const Text(
            'Indbakke',
            style: TextStyle(
              color: Colors.white70,
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
                  return InboxListTile(
                    msg: msg,
                    onTap: () async {
                      final changed = await Navigator.pushNamed(
                        context,
                        '/patient/message_detail',
                        arguments: msg['thread_id'],
                      );

                      if (changed == true) {
                        _loadMessages();
                      }
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
                      .then((value) {
                    if (value == true) _loadMessages();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Ny besked'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white70,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
