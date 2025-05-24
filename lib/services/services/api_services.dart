import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';

  // 🔐 TOKEN MANAGEMENT
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

  // 🌐 GENERIC HTTP METHODS
  static Future<http.Response> _get(String endpoint) async {
    final headers = await _authHeaders();
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> _delete(String endpoint) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> _patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // 👤 AUTHENTICATION
  static Future<Map<String, dynamic>> simulatedLogin(String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sim-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sim_userid': userId, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      return data;
    } else {
      throw Exception('Login fejlede: ${response.statusCode}');
    }
  }

  // 👥 PATIENT METHODS
  static Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    try {
      final response = await _get('/patients/search?q=$query');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        throw Exception('Ikke autoriseret - log venligst ind igen');
      } else {
        throw Exception('Fejl ved søgning: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Netværksfejl: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getPatientDetails(int patientId) async {
    final response = await _get('/patients/$patientId');
    return _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getPatientSensors(int patientId) async {
    final response = await _get('/patients/$patientId/sensors');
    return _handleListResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getPatientEvents(int patientId) async {
    final response = await _get('/patients/$patientId/events');
    return _handleListResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getBatteryStatus(int patientId) async {
    final response = await _get('/patients/$patientId/battery');
    return _handleListResponse(response);
  }



  // ✉️ MESSAGE METHODS
  static Future<List<Map<String, dynamic>>> fetchInbox() async {
    final response = await _get('/messages/inbox');
    return _handleListResponse(response, key: 'messages');
  }

  static Future<List<Map<String, dynamic>>> fetchThread(int threadId) async {
    final response = await _get('/messages/thread-by-id/$threadId');
    return _handleListResponse(response);
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
    final response = await _post('/messages/send', payload);
    _handleVoidResponse(response, successCode: 200);
  }


  static Future<void> markThreadAsRead(int threadId) async {
    final response = await _patch('/messages/thread/$threadId/read', {});
    _handleVoidResponse(response, successCode: 204);
  }

  static Future<void> deleteThread(int threadId) async {
    final response = await _delete('/messages/thread/$threadId');
    _handleVoidResponse(response, successCode: 204);
  }

  static Future<List<Map<String, dynamic>>> fetchRecipients() async {
    final response = await _get('/messages/recipients');
    return _handleListResponse(response);
  }

  static Future<List<Map<String, dynamic>>> fetchClinicianPatients() async {
    final response = await _get('/clinician/patients');
    return _handleListResponse(response);
  }

  // 📅 ACTIVITY METHODS
  static Future<List<Map<String, dynamic>>> fetchActivities(int patientId) async {
    final response = await _get('/activities?patient_id=$patientId');
    return _handleListResponse(response);
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
    final response = await _post('/activities', payload);
    _handleVoidResponse(response, successCode: 201);
  }

  static Future<void> deleteActivity(int activityId, {required String userId}) async {
    final response = await _delete('/activities/$activityId?user_id=$userId');
    _handleVoidResponse(response, successCode: 200);
  }

  static Future<void> addActivityLabel(String label) async {
    final response = await _post('/patient/activity-labels', {'label': label});
    _handleVoidResponse(response, successCode: 201);
  }

  static Future<List<String>> fetchActivityLabels() async {
    final response = await _get('/patient/activity-labels');
    return List<String>.from(jsonDecode(response.body));
  }

  // QUESTION METHODS
  static Future<List<dynamic>> fetchQuestions() async {
    final response = await _get('/questions');
    return _handleDynamicListResponse(response);
  }

  // 🔄 PAGINATION
  static Future<List<Map<String, dynamic>>> fetchPaginatedData(String endpoint) async {
    final List<Map<String, dynamic>> allData = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final response = await _get('$endpoint?page=$page');
      final data = jsonDecode(response.body);
      final items = data['items'] as List;
      allData.addAll(items.cast<Map<String, dynamic>>());
      hasMore = data['hasMore'] as bool;
      page++;
    }

    return allData;
  }



  // BLE DATA MANAGEMENT
  static Future<int?> registerSensorUse({
    required int patientId,
    required String deviceSerial,
    required String jwt,
  }) async {
    final url = Uri.parse("$baseUrl/register-sensor-use");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'patient_id': patientId,
        'device_serial': deviceSerial,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["sensor_id"];
    } else {
      print("❌ Fejl ved sensor-registrering: ${response.body}");
      return null;
    }
  }

  static Future<void> sendBatteryStatus({
    required int patientId,
    required int sensorId,
    required int batteryLevel,
    required String jwt,
  }) async {
    final url = Uri.parse("$baseUrl/patient-battery-status");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'patient_id': patientId,
        'sensor_id': sensorId,
        'battery_level': batteryLevel,
      }),
    );

    if (response.statusCode == 201) {
      print("✅ Batteriniveau sendt til backend");
    } else {
      print("❌ Fejl ved batteri-API: ${response.body}");
    }
  }

  static const String lightDataEndpoint = "$baseUrl/patient-light-data";
  static Future<bool> sendLightData(Map<String, dynamic> data, String jwt) async {
    final url = Uri.parse("$baseUrl/patient-light-data");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      print("✅ Light data sendt succesfuldt");
      return true;
    } else {
      print("❌ Fejl ved sendLightData: ${response.statusCode} ${response.body}");
      return false;
    }
  }


  // 🛠 HELPER METHODS
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Ressource ikke fundet');
    } else {
      throw Exception('Fejl: ${response.statusCode}');
    }
  }

  static List<Map<String, dynamic>> _handleListResponse(http.Response response, {String? key}) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(key != null ? data[key] : data);
    } else {
      throw Exception('Fejl: ${response.statusCode}');
    }
  }

  static List<dynamic> _handleDynamicListResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fejl: ${response.statusCode}');
    }
  }

  static void _handleVoidResponse(http.Response response, {required int successCode}) {
    if (response.statusCode != successCode) {
      throw Exception('Fejl: ${response.statusCode}');
    }
  }
}