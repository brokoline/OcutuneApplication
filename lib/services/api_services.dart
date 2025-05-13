import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';

  // Hent spørgsmål (eksisterende)
  static Future<List<dynamic>> fetchQuestions() async {
    print('📡 Trying to fetch questions from $baseUrl/questions');
    try {
      final response = await http.get(Uri.parse('$baseUrl/questions'));

      print('🔁 Response status code: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception caught while fetching questions: $e');
      rethrow;
    }
  }

  // Henter seneste patients fornavn (og efternavn til kliniker-dashboardet)
  static Future<Map<String, String>> fetchLatestPatientName() async {
    final url = '$baseUrl/latest-patient';
    print('📡 Fetching latest patient from $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('🔁 Response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'first_name': data['first_name'] ?? 'Bruger',
          'last_name': data['last_name'] ?? '',
        };
      } else {
        throw Exception('❌ Failed to load patient');
      }
    } catch (e) {
      print('💥 Error: $e');
      return {
        'first_name': 'Bruger',
        'last_name': '',
      };
    }
  }

  /// Send besked fra patient til tilknyttet behandler
  static Future<void> sendPatientMessage({
    required int patientId,
    required String message,
  }) async {
    final url = '$baseUrl/patient-contact';
    print('📡 POST til $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'message': message,
        }),
      );

      print('🔁 Statuskode: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('❌ Fejl ved afsendelse af besked: ${response.body}');
      }
    } catch (e) {
      print('💥 Exception i sendPatientMessage: $e');
      rethrow;
    }
  }

  // beskedhistorik
  static Future<List<Map<String, dynamic>>> getPatientMessages(int patientId) async {
    final url = '$baseUrl/messages/$patientId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Kunne ikke hente beskeder');
    }
  }

}