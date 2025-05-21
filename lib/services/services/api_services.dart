import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth_storage.dart';

class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Mangler token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }



// Simuleret MitID-login
  static Future<Map<String, dynamic>> simulatedLogin(String userId, String password) async {
    final url = Uri.parse('$baseUrl/sim-login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sim_userid': userId,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      // Venter eksplicit på at token er gemt
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      print('✅ Token gemt i SharedPreferences: $token');
      return data;
    } else {
      print('❌ Login fejlede med status: ${response.statusCode}');
      throw Exception('Login fejlede');
    }
  }





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

  static Future<void> markThreadAsRead(int threadId) async {
    final token = await AuthStorage.getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/threads/$threadId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Kunne ikke markere som læst');
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

  static Future<void> deleteThread(int threadId) async {
    final token = await AuthStorage.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/threads/$threadId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('🧪 Statuskode fra server: ${response.statusCode}');

    if (response.statusCode != 204) {
      throw Exception('Kunne ikke slette tråd');
    }
  }

// Kliniker inbakke beskeder
  static Future<List<Map<String, dynamic>>> getClinicianInboxMessages() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Missing token - cannot fetch inbox');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/messages/clinician-inbox'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Unknown error';
        throw Exception('❌ Error fetching inbox: $errorMsg');
      } catch (e) {
        throw Exception('❌ Error fetching inbox - response not in JSON format.');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getClinicianMessageThreadById(int threadId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) throw Exception('Mangler token');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/clinician-thread-by-id/$threadId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 GET /messages/clinician-thread-by-id/$threadId');
      print('🔁 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        // Return an empty list instead of throwing an exception
        return [];
      } else if (response.statusCode == 404) {
        throw Exception('Beskedtråd ikke fundet');
      } else {
        throw Exception('Serverfejl: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fejl i getClinicianMessageThreadById: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getClinicianPatients() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/clinician/patients'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Could not fetch patients');
    }
  }

  static Future<void> sendClinicianMessage({
    required String message,
    String subject = '',
    int? replyTo,
    int? patientId,
  }) async {
    final token = await getToken();

    final Map<String, dynamic> payload = {
      'message': message,
      'subject': subject,
    };

    if (replyTo != null) payload['reply_to'] = replyTo;
    if (patientId != null) payload['patient_id'] = patientId;

    final response = await http.post(
      Uri.parse('$baseUrl/clinician-contact'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Error sending message');
    }
  }




  // Patient aktiviteter
  static Future<List<Map<String, dynamic>>> fetchActivities(int patientId) async {
    final url = Uri.parse('$baseUrl/activities?patient_id=$patientId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load activities');
    }
  }


  static Future<void> addActivity(String eventType, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'event_type': eventType, 'note': note}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add activity');
    }
  }

  static Future<void> addActivityWithTimes({
    required int patientId,
    required String eventType,
    required String note,
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) async {
    final url = Uri.parse('$baseUrl/activities');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patient_id': patientId,
        'event_type': eventType,
        'note': note,
        'start_time': startTime,
        'end_time': endTime,
        'duration_minutes': durationMinutes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add activity');
    }
  }

  static Future<void> addActivityLabel(String label) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/patient/activity-labels'),
      headers: headers,
      body: jsonEncode({'label': label}),
    );
    if (response.statusCode != 201) {
      throw Exception('Kunne ikke tilføje aktivitetstype');
    }
  }

  static Future<List<String>> fetchActivityLabels() async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl/patient/activity-labels');
    final response = await http.get(url, headers: headers);

    print('📡 GET $url');
    print('📥 Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Kunne ikke hente aktivitetstyper');
    }
  }




  static Future<void> deleteActivity(int activityId, {required String userId}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/activities/$activityId?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Fejl ved sletning: ${response.body}');
    }
  }


}





// BLE Forbindelse


