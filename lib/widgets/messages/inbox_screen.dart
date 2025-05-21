import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocutune_light_logger/services/services/message_service.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';
import 'dart:io';


class InboxScreen extends StatefulWidget {
  final UserRole role;

  const InboxScreen({super.key, required this.role});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await MessageService.fetchInbox(widget.role);
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
            widget.role == UserRole.patient ? 'Indbakke' : 'Kliniker-indbakke',
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
                        widget.role == UserRole.patient
                            ? '/patient/message_detail'
                            : '/clinician/message_detail',
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
                  Navigator.pushNamed(
                    context,
                    widget.role == UserRole.patient
                        ? '/patient/new_message'
                        : '/clinician/new_message',
                  ).then((value) {
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
