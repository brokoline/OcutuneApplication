import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/api_services.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

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
      setState(() {
        _clinicians = list;
        if (list.length == 1) {
          _selectedClinicianId = list.first['id'];
          _selectedClinicianName = list.first['name'];
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

    if (patientId == null || body.isEmpty || _selectedClinicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Udfyld emne, besked og vælg behandler')),
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
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ny besked',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Vælg behandler
            DropdownButtonFormField<int>(
              value: _selectedClinicianId,
              dropdownColor: generalBox,
              iconEnabledColor: Colors.white,
              decoration: const InputDecoration(
                labelText: 'Vælg behandler',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
              items: _clinicians
                  .map((c) => DropdownMenuItem<int>(
                value: c['id'],
                child: Text(c['name'], style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (val) {
                final selected = _clinicians.firstWhere((c) => c['id'] == val);
                setState(() {
                  _selectedClinicianId = val;
                  _selectedClinicianName = selected['name'];
                });
              },
            ),
            const SizedBox(height: 8),

            if (_selectedClinicianName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Skriv til: $_selectedClinicianName',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Emnefelt
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Emne',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Beskedfelt
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Skriv din besked...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Send-knap
            ElevatedButton.icon(
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
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sender...' : 'Send besked'),
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
}
