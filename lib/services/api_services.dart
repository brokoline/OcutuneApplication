import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';



  // Hent spørgsmål
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


  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('🪪 Token i Flutter: $token');
    return token;
  }

  static Future<List<Map<String, dynamic>>> getInboxMessages() async {
    final token = await getToken();

    print('🔐 JWT token: $token');
    if (token == null || token.isEmpty) {
      throw Exception('Token mangler – kan ikke hente indbakke');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/messages/inbox'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 GET /messages/inbox');
    print('🔁 Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Ukendt fejl';
        throw Exception('❌ Fejl ved hentning af indbakke: $errorMsg');
      } catch (e) {
        throw Exception('❌ Fejl ved hentning af indbakke – svar ikke i JSON-format.');
      }
    }
  }


  static Future<Map<String, dynamic>> getMessageDetail(int messageId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/detail/$messageId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Besked ikke fundet');
    }
  }

  static Future<List<Map<String, dynamic>>> getMessageThreadById(int threadId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/thread-by-id/$threadId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Kunne ikke hente samtale');
    }
  }

  static Future<void> sendPatientMessage({
    required String message,
    String subject = '',
    int? replyTo,
    int? clinicianId,
  }) async {
    final token = await getToken();

    final Map<String, dynamic> payload = {
      'message': message,
      'subject': subject,
    };

    if (replyTo != null) payload['reply_to'] = replyTo;
    if (clinicianId != null) payload['clinician_id'] = clinicianId;

    final response = await http.post(
      Uri.parse('$baseUrl/patient-contact'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Fejl ved afsendelse af besked');
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientClinicians() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/patient/clinicians'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Kunne ikke hente behandlere');
    }
  }

  // BLE Forbindelse


}