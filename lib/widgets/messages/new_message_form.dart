import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../services/services/message_service.dart';
import '../../theme/colors.dart';
import '../ocutune_textfield.dart';

class NewMessageForm extends StatefulWidget {
  final UserRole senderRole;

  const NewMessageForm({super.key, required this.senderRole});

  @override
  State<NewMessageForm> createState() => _NewMessageFormState();
}

class _NewMessageFormState extends State<NewMessageForm> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  int? _selectedReceiverId;
  String? _selectedReceiverName;
  List<Map<String, dynamic>> _recipients = [];

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    try {
      final list = await MessageService.getRecipients(widget.senderRole);

      final unique = {
        for (var c in list) c['id']: c
      }.values.toList();

      if (!mounted) return;

      setState(() {
        _recipients = unique;
        if (unique.length == 1) {
          final single = unique.first;
          _selectedReceiverId = single['id'];
          _selectedReceiverName = _extractName(single);
        } else {
          _selectedReceiverId = null;
          _selectedReceiverName = null;
        }
      });
    } catch (e) {
      debugPrint('❌ Fejl ved hentning af modtagere: $e');
    }
  }

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final body = _messageController.text.trim();

    if (_selectedReceiverId == null || subject.isEmpty || body.isEmpty) {
      final msg = _selectedReceiverId == null
          ? 'Vælg venligst en modtager'
          : subject.isEmpty
          ? 'Angiv venligst et emne'
          : 'Skriv venligst en besked';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await MessageService.send(
        senderRole: widget.senderRole,
        receiverId: _selectedReceiverId!,
        subject: subject,
        message: body,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Besked sendt')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Kunne ikke sende besked')),
      );
    }

    if (!mounted) return;
    setState(() => _sending = false);
  }

  String _extractName(Map c) {
    return c['full_name'] ??
        c['name'] ??
        '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim() ??
        'Ukendt';
  }

  @override
  Widget build(BuildContext context) {
    final multiple = _recipients.length > 1;
    final validValue = _selectedReceiverId != null &&
        _recipients.any((c) => c['id'] == _selectedReceiverId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (multiple)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DropdownButtonFormField2<int>(
                isExpanded: true,
                value: validValue ? _selectedReceiverId : null,
                iconStyleData: const IconStyleData(iconEnabledColor: Colors.white70),
                decoration: InputDecoration(
                  labelText: 'Vælg modtager',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: generalBox,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    color: generalBoxHover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _recipients.map((c) {
                  final name = _extractName(c);
                  final isSelected = c['id'] == _selectedReceiverId;

                  return DropdownMenuItem<int>(
                    value: c['id'],
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 16, color: Colors.white54),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  final selected =
                  _recipients.firstWhere((c) => c['id'] == val, orElse: () => {});
                  setState(() {
                    _selectedReceiverId = val;
                    _selectedReceiverName = _extractName(selected);
                  });
                },
              ),
            )
          else if (_selectedReceiverName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Skriv til: $_selectedReceiverName',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 16),
          OcutuneTextField(
            label: 'Emne',
            controller: _subjectController,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white),
            minLines: 11,
            maxLines: 11,
            decoration: InputDecoration(
              filled: true,
              fillColor: generalBox,
              hintText: 'Skriv din besked...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 140,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
                    : const Icon(Icons.send, size: 18),
                label: Text(_sending ? 'Sender...' : 'Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white70,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
