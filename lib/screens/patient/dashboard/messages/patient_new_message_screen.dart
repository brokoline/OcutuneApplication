import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_textfield.dart';

class PatientNewMessageScreen extends StatefulWidget {
  const PatientNewMessageScreen({super.key});

  @override
  State<PatientNewMessageScreen> createState() => _PatientNewMessageScreenState();
}

class _PatientNewMessageScreenState extends State<PatientNewMessageScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  int? _selectedClinicianId;
  String? _selectedClinicianName;
  List<Map<String, dynamic>> _clinicians = [];

  @override
  void initState() {
    super.initState();
    _loadClinicians();
  }

  Future<void> _loadClinicians() async {
    final patientId = await AuthStorage.getUserId();
    if (patientId == null) return;

    try {
      final list = await ApiService.getPatientClinicians(patientId);

      // Fjern dubletter baseret på id
      final unique = {
        for (var c in list) c['id']: c
      }.values.toList();

      setState(() {
        _clinicians = unique;
        if (unique.length == 1) {
          _selectedClinicianId = unique.first['id'];
          _selectedClinicianName = unique.first['name'];
        } else {
          _selectedClinicianId = null;
          _selectedClinicianName = null;
        }
      });
    } catch (e) {
      print('❌ Fejl ved hentning af klinikere: $e');
    }
  }

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final body = _messageController.text.trim();
    final patientId = await AuthStorage.getUserId();

    if (patientId == null) return;

    if (_selectedClinicianId == null || subject.isEmpty || body.isEmpty) {
      String msg;
      if (_selectedClinicianId == null && subject.isEmpty && body.isEmpty) {
        msg = 'Vælg venligst en behandler, angiv et emne og skriv en besked';
      } else if (_selectedClinicianId == null) {
        msg = 'Vælg venligst en behandler';
      } else if (subject.isEmpty) {
        msg = 'Angiv venligst et emne';
      } else {
        msg = 'Skriv venligst en besked';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await ApiService.sendPatientMessage(
        patientId: patientId,
        message: body,
        subject: subject,
        clinicianId: _selectedClinicianId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Besked sendt')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Kunne ikke sende besked')),
      );
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final multiple = _clinicians.length > 1;
    final validValue = _selectedClinicianId != null &&
        _clinicians.any((c) => c['id'] == _selectedClinicianId);

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ny besked',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Icon(Icons.mail_outline, color: Colors.white, size: 48)),
            const SizedBox(height: 40),

            if (multiple)
              DropdownButtonFormField<int>(
                value: validValue ? _selectedClinicianId : null,
                dropdownColor: generalBox,
                iconEnabledColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: generalBox,
                  labelText: 'Vælg behandler',
                  labelStyle: const TextStyle(color: Colors.white70),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _clinicians.map((c) => DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name'], style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (val) {
                  final selected = _clinicians.firstWhere((c) => c['id'] == val, orElse: () => {});
                  setState(() {
                    _selectedClinicianId = val;
                    _selectedClinicianName = selected['name'];
                  });
                },
              )
            else if (_selectedClinicianName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Skriv til: $_selectedClinicianName',
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
              minLines: 8,
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
                    backgroundColor: Colors.white,
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
