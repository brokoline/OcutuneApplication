import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';


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

      final httpDateFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
      final Map<int, Map<String, dynamic>> threadMap = {};

      for (var msg in msgs) {
        final threadId = msg['thread_id'];
        final sentAt = httpDateFormat.parse(msg['sent_at']);

        if (!threadMap.containsKey(threadId) ||
            sentAt.isAfter(httpDateFormat.parse(threadMap[threadId]!['sent_at']))) {
          threadMap[threadId] = {
            ...msg,
            'display_name': msg['sender_id'] == currentUserId
                ? msg['receiver_name']
                : msg['sender_name'],
          };
        }
      }

      final rootMessages = threadMap.values.toList()
        ..sort((a, b) => httpDateFormat
            .parse(b['sent_at'])
            .compareTo(httpDateFormat.parse(a['sent_at'])));

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
                        _loadMessages(); // opdater inbox automatisk
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
                      .then((_) => _loadMessages());
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
