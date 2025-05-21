import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';

  // 🔐 TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null) throw Exception('Mangler token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 🌐 GENERELLE HTTP METODER
  static Future<http.Response> get(String endpoint) async {
    final headers = await _authHeaders();
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.patch(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  // 👤 LOGIN
  static Future<Map<String, dynamic>> simulatedLogin(String userId, String password) async {
    final url = Uri.parse('$baseUrl/sim-login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sim_userid': userId, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      return data;
    } else {
      throw Exception('Login fejlede');
    }
  }

  // ✉️ MESSAGES
  static Future<List<Map<String, dynamic>>> fetchInbox() async {
    final res = await get('/messages/inbox');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body)['messages']);
  }

  static Future<List<Map<String, dynamic>>> fetchThread(int threadId) async {
    final res = await get('/messages/thread/$threadId');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<void> sendMessage({
    required int receiverId,
    required String message,
    String subject = '',
    int? replyTo,
  }) async {
    final payload = {
      'receiver_id': receiverId,
      'message': message,
      'subject': subject,
      if (replyTo != null) 'reply_to': replyTo,
    };
    final res = await post('/messages/send', payload);
    if (res.statusCode != 200) {
      throw Exception('Kunne ikke sende besked');
    }
  }

  static Future<void> markThreadAsRead(int threadId) async {
    final res = await patch('/messages/thread/$threadId/read', {});
    if (res.statusCode != 204) {
      throw Exception('Kunne ikke markere tråd som læst');
    }
  }

  static Future<void> deleteThread(int threadId) async {
    final res = await delete('/messages/thread/$threadId');
    if (res.statusCode != 204) {
      throw Exception('Kunne ikke slette tråd');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecipients() async {
    final res = await get('/messages/recipients');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> fetchClinicianPatients() async {
    final res = await get('/clinician/patients');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  // 🧠 SPØRGSMÅL
  static Future<List<dynamic>> fetchQuestions() async {
    final res = await http.get(Uri.parse('$baseUrl/questions'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Kunne ikke hente spørgsmål');
    }
  }

  // 📅 AKTIVITETER
  static Future<List<Map<String, dynamic>>> fetchActivities(int patientId) async {
    final res = await http.get(Uri.parse('$baseUrl/activities?patient_id=$patientId'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception('Kunne ikke hente aktiviteter');
    }
  }

  static Future<void> addActivity({
    required String eventType,
    required String note,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    int? patientId,
  }) async {
    final payload = {
      'event_type': eventType,
      'note': note,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (patientId != null) 'patient_id': patientId,
    };

    final res = await post('/activities', payload);
    if (res.statusCode != 201) {
      throw Exception('Kunne ikke oprette aktivitet');
    }
  }

  static Future<void> deleteActivity(int activityId, {required String userId}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/activities/$activityId?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Fejl ved sletning af aktivitet');
    }
  }

  static Future<void> addActivityLabel(String label) async {
    final res = await post('/patient/activity-labels', {'label': label});
    if (res.statusCode != 201) {
      throw Exception('Kunne ikke tilføje label');
    }
  }

  static Future<List<String>> fetchActivityLabels() async {
    final res = await get('/patient/activity-labels');
    return List<String>.from(jsonDecode(res.body));
  }
}
