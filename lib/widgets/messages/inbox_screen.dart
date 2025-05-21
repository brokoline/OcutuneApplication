import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocutune_light_logger/services/services/message_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String _role = 'patient'; // fallback

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadMessages();
  }

  Future<void> _loadUserRole() async {
    final payload = await AuthStorage.getTokenPayload();
    setState(() {
      _role = payload['role'] ?? 'patient';
    });
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await MessageService.fetchInbox();
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
    final detailRoute =
    _role == 'clinician' ? '/clinician/message_detail' : '/patient/message_detail';
    final newMessageRoute =
    _role == 'clinician' ? '/clinician/new_message' : '/patient/new_message';

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
          title: Text(
            _role == 'clinician' ? 'Kliniker-indbakke' : 'Indbakke',
            style: const TextStyle(
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
                        detailRoute,
                        arguments: msg['thread_id'],
                      );
                      if (changed == true) _loadMessages();
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, newMessageRoute)
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
