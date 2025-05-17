import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteErrorLogger {
  static Future<void> log({
    required int patientId,
    required String type,
    required String message,
  }) async {
    try {
      await http.post(
        Uri.parse('http://192.168.64.6:5000/log-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'type': type,
          'message': message,
        }),
      );
    } catch (_) {
      // Bevidst tomt – vi forsøger ikke at logge log-fejl......
    }
  }
}
