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


  // henter patient til login
  static Future<Map<String, dynamic>> getPatientInfo(String simUserId) async {
    final response = await http.get(Uri.parse('$baseUrl/patient-info/$simUserId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Kunne ikke hente patientinfo');
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
  /// Send besked fra patient til kliniker
  static Future<void> sendPatientMessage({
    required int patientId,
    required String message,
    String subject = '',
    int? replyTo,
    int? clinicianId,
  }) async {
    final Map<String, dynamic> payload = {
      'patient_id': patientId,
      'message': message,
      'subject': subject,
    };

    if (replyTo != null) {
      payload['reply_to'] = replyTo;
    }

    if (clinicianId != null) {
      payload['clinician_id'] = clinicianId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/patient-contact'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      print('❌ Backend-fejl: ${response.statusCode} ${response.body}');
      throw Exception('❌ Fejl ved afsendelse af besked');
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

  // Indbakke
  static Future<List<Map<String, dynamic>>> getInboxMessages(int patientId) async {
    final url = '$baseUrl/messages/inbox/$patientId';
    print('📡 GET $url');
    final response = await http.get(Uri.parse(url));

    print('🔁 Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Kunne ikke hente beskeder (${response.statusCode}): ${response.body}');
    }
  }


  // Hent én besked (detail)
  static Future<Map<String, dynamic>> getMessageDetail(int messageId) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/detail/$messageId'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Besked ikke fundet');
    }
  }

  // hent tråd baseret på besked-ID (fx første besked eller svar)
  static Future<List<Map<String, dynamic>>> getMessageThreadById(int threadId) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/thread-by-id/$threadId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Kunne ikke hente samtale');
    }
  }

  // patient kliniker forhold
  static Future<List<Map<String, dynamic>>> getPatientClinicians(int patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/patient/$patientId/clinicians'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Kunne ikke hente behandlere');
    }
  }

}
