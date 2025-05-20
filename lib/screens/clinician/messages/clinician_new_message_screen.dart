import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ocutune_light_logger/services/api_services.dart' as api;
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_textfield.dart';

class ClinicianNewMessageScreen extends StatefulWidget {
  const ClinicianNewMessageScreen({super.key});

  @override
  State<ClinicianNewMessageScreen> createState() => _ClinicianNewMessageScreenState();
}

class _ClinicianNewMessageScreenState extends State<ClinicianNewMessageScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  int? _selectedPatientId;
  String? _selectedPatientName;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final list = await api.ApiService.getClinicianPatients();
      final unique = {
        for (var p in list) p['id']: p
      }.values.toList();
      print('Patienter hentet: $list');

      setState(() {
        _patients = unique;
        if (unique.length == 1) {
          _selectedPatientId = unique.first['id'];
          _selectedPatientName = unique.first['name'];
        } else {
          _selectedPatientId = null;
          _selectedPatientName = null;
        }
      });
    } catch (e) {
      print('❌ Fejl ved hentning af patienter: $e');
    }
  }

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final body = _messageController.text.trim();

    if (_selectedPatientId == null || subject.isEmpty || body.isEmpty) {
      String msg;
      if (_selectedPatientId == null && subject.isEmpty && body.isEmpty) {
        msg = 'Vælg en patient, skriv et emne og indhold.';
      } else if (_selectedPatientId == null) {
        msg = 'Vælg en patient';
      } else if (subject.isEmpty) {
        msg = 'Skriv et emne';
      } else {
        msg = 'Skriv en besked';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await api.ApiService.sendClinicianMessage(
        message: body,
        subject: subject,
        patientId: _selectedPatientId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Besked sendt')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Fejl under afsendelse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Kunne ikke sende besked')),
      );
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final multiple = _patients.length > 1;
    final validValue = _selectedPatientId != null &&
        _patients.any((p) => p['id'] == _selectedPatientId);

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Ny besked',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Icon(Icons.mail_outline, color: Colors.white70, size: 48)),
            const SizedBox(height: 40),

            if (multiple)
              DropdownButtonFormField2<int>(
                isExpanded: true,
                value: validValue ? _selectedPatientId : null,
                iconStyleData: const IconStyleData(iconEnabledColor: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Vælg patient',
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
                  decoration: BoxDecoration(
                    color: generalBoxHover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _patients.map((p) {
                  return DropdownMenuItem<int>(
                    value: p['id'],
                    child: Text(
                      '${p['first_name']} ${p['last_name']}',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  final selected = _patients.firstWhere((p) => p['id'] == val, orElse: () => {});
                  setState(() {
                    _selectedPatientId = val;
                    _selectedPatientName = selected['name'];
                  });
                },
              )
            else if (_selectedPatientName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Skriv til: $_selectedPatientName',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),

            const SizedBox(height: 22),

            OcutuneTextField(
              label: 'Emne',
              controller: _subjectController,
            ),
            const SizedBox(height: 22),

            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              minLines: 10,
              maxLines: 10,
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

            const SizedBox(height: 34),

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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
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
      ),
    );
  }
}
