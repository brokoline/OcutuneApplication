// lib/services/services/api_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/light_data_model.dart';
import '../../models/patient_model.dart';
import '../auth_storage.dart';


/// Base URL for alle API‐kald. (Ingen trailing slash i _baseUrl)
const String _baseUrl = "https://ocutune2025.ddns.net";

class ApiService {
  static const String baseUrl = _baseUrl;

  //─────────────────────────────────────────────────────────────────────────────
  // 1) Helper: Returner JWT‐token fra SharedPreferences
  //─────────────────────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 2) Helper: Returner headers med JWT‐token
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null) throw Exception('Mangler token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 3) Helper: HTTP GET (indsætter "/api" foran endpointet)
  //─────────────────────────────────────────────────────────────────────────────
  static Future<http.Response> _get(String endpoint) async {
    final headers = await _authHeaders();
    return http.get(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: headers,
    );
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 4) Helper: HTTP POST (indsætter "/api" foran endpointet)
  //─────────────────────────────────────────────────────────────────────────────
  static Future<http.Response> _post(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.post(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 5) Helper: HTTP DELETE (indsætter "/api" foran endpointet)
  //─────────────────────────────────────────────────────────────────────────────
  static Future<http.Response> _delete(String endpoint) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse('$baseUrl/api$endpoint'), headers: headers);
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 6) Helper: HTTP PATCH (indsætter "/api" foran endpointet)
  //─────────────────────────────────────────────────────────────────────────────
  static Future<http.Response> _patch(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.patch(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 7) Helper: Behandl “list”‐response
  //─────────────────────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _handleListResponse(
      http.Response response, {
        String? key,
      }) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (key != null &&
          data is Map<String, dynamic> &&
          data.containsKey(key)) {
        return List<Map<String, dynamic>>.from(data[key]);
      }
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception("Forventede JSON List eller objekt med '$key'");
    } else {
      throw Exception("HTTP ${response.statusCode} – ${response.reasonPhrase}");
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 8) Helper: Håndter “single”‐response (ikke list)
  //─────────────────────────────────────────────────────────────────────────────
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Ressource ikke fundet');
    } else {
      throw Exception('Fejl: ${response.statusCode}');
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 9) Helper: Håndter “void”‐operation (POST/DELETE/PATCH uden JSON‐body)
  //─────────────────────────────────────────────────────────────────────────────
  static void _handleVoidResponse(
      http.Response response, {
        required int successCode,
      }) {
    if (response.statusCode != successCode) {
      throw Exception('Fejl: ${response.statusCode}');
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 10) Al lysdata for én patient, og daglige, ugentlige og månedlige lysdata
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPatientLightData(
      String patientId) async {
    final response = await _get('/patients/$patientId/lightdata');
    return _handleListResponse(response);
  }

  static Future<List<LightData>> fetchDailyLightData({
    required String patientId,
  }) async {
    final response = await _get("/patients/$patientId/lightdata/daily");
    final rawList = _handleListResponse(response);
    return rawList.map((jsonMap) => LightData.fromJson(jsonMap)).toList();
  }

  static Future<List<LightData>> fetchWeeklyLightData({
    required String patientId,
  }) async {
    final response = await _get("/patients/$patientId/lightdata/weekly");
    final rawList = _handleListResponse(response);
    return rawList.map((jsonMap) => LightData.fromJson(jsonMap)).toList();
  }

  static Future<List<LightData>> fetchMonthlyLightData({
    required String patientId,
  }) async {
    final response = await _get("/patients/$patientId/lightdata/monthly");
    final rawList = _handleListResponse(response);
    return rawList.map((jsonMap) => LightData.fromJson(jsonMap)).toList();
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 11) Authentication (Login) – gemmer JWT i SharedPreferences
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> simulatedLogin(
      String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/mitid/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sim_userid': userId, 'sim_password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      // Gemmer token under nøglen 'jwt_token'
      await prefs.setString('jwt_token', data['token']);
      return data;
    } else {
      throw Exception('Login fejlede: ${response.statusCode}');
    }
  }
  //─────────────────────────────────────────────────────────────────────────────
  // 12) Kliniker: Hent liste over patienter
  //     GET /api/clinician/patients
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getClinicianPatients() async {
    final response = await _get('/clinician/patients');
    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> getClinicianPatientDetail(
      String id) async {
    final response = await _get('/clinician/patients/$id');
    return _handleResponse(response);
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 13) Søg patienter for kliniker
  //     GET /api/patients/search?q=<søgetekst>
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    // 1) Trim og returnér tom liste, hvis query er tom eller kun whitespace
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    try {
      // 2) Hent JWT‐token
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Ingen token fundet – log ind først');
      }

      // 3) URL‐encode søgetermen, så fx mellemrum osv. bliver korrekte i URL'en
      final encoded = Uri.encodeQueryComponent(trimmed);
      final url = Uri.parse('$baseUrl/api/patients/search?q=$encoded');

      // 4) Send GET med Authorization‐header
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 5) Håndter forskellige HTTP‐koder
      switch (response.statusCode) {
        case 200:
        // Forvent en liste af JSON‐objekter
          final data = jsonDecode(response.body) as List;
          return data.cast<Map<String, dynamic>>();

        case 403:
          throw Exception('Du har ikke adgang til at søge patienter (403)');

        case 422:
        // “q” var måske kun whitespace (men vi filtrerede den selv ud), eller
        // server betragter den stadig som ugyldig – returnér bare tom liste
          return [];

        default:
          throw Exception(
            'Fejl ved søgning: ${response.statusCode} ${response.reasonPhrase} ${response.body}',
          );
      }
    } catch (e) {
      rethrow;
    }
  }


  //─────────────────────────────────────────────────────────────────────────────
  // 14) Patient‐detaljer & relaterede kald
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Patient> getPatientDetails(String patientId) async {
    final response = await _get('/patients/$patientId');
    final data = _handleResponse(response);
    return Patient.fromJson(data);
  }

  static Future<List<Map<String, dynamic>>> getPatientDiagnoses(
      String patientId) async {
    final response = await _get('/patients/$patientId/diagnoses');
    return _handleListResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getPatientSensors(
      String patientId) async {
    final response = await _get('/sensor/patients/$patientId/sensors');
    return _handleListResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getPatientEvents(
      String patientId) async {
    final response = await _get('/patients/$patientId/events');
    return _handleListResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getBatteryStatus(
      String patientId) async {
    final response = await _get('/sensor/patients/$patientId/battery');
    return _handleListResponse(response);
  }

  static Future<bool> reportBatteryStatus(
      String patientId,
      int batteryLevel, {
        int? sensorId,
      }) async {
    // 1) Sammensæt payload
    final Map<String, dynamic> payload = {
      'patient_id': patientId,
      'sensor_id': sensorId,
      'battery_level': batteryLevel,
    };
    payload.removeWhere((_, v) => v == null);

    // 2) Byg headers (indkluder eventuel JWT, hvis du bruger det)
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      // Hvis du har JWT-autentifikation, tilføj fx:
      // 'Authorization': 'Bearer $jwtToken',
    };

    // 3) Læg mærke til den præcise sti: '/api/sensor/patient-battery-status'
    final Uri uri = Uri.parse('$_baseUrl/api/sensor/patient-battery-status');

    // 4) Send POST‐anmodningen
    final http.Response response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    // 5) Hvis serveren returnerer andet end 200 eller 400, kast en Exception
    if (response.statusCode != 200 && response.statusCode != 400) {
      throw Exception(
          'Uventet statuskode: ${response.statusCode}. Body: ${response.body}');
    }

    // 6) Parse JSON‐svaret
    final Map<String, dynamic> jsonBody = jsonDecode(response.body);

    // 7) Tjek om "success" findes og er en bool
    if (jsonBody.containsKey('success') && jsonBody['success'] is bool) {
      return jsonBody['success'] as bool;
    } else {
      throw Exception('Ugyldigt JSON‐svar fra server: ${response.body}');
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 15) Beskeder (Messages)
  //     • Hent indbakke: GET /api/messages/inbox
  //     • Hent tråd:    GET /api/messages/thread-by-id/<threadId>
  //     • Send besked:  POST /api/messages
  //     • Markér som læst: PATCH /api/messages/thread/<threadId>/read
  //     • Slet tråd:      DELETE /api/messages/thread/<threadId>
  //     • Hent modtagere: GET /api/messages/recipients
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchInbox() async {
    final response = await _get('/messages/inbox');
    return _handleListResponse(response, key: 'messages');
  }

  static Future<List<Map<String, dynamic>>> fetchThread(
      String threadId) async {
    final response = await _get('/messages/thread-by-id/$threadId');
    return _handleListResponse(response);
  }

  static Future<void> sendMessage({
    required String receiverId,
    required String message,
    String subject = '',
    dynamic replyTo,
  }) async {
    final cleanSubject =
    subject.trim().isNotEmpty ? subject.trim() : 'Uden emne';
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      throw Exception('Besked kan ikke være tom');
    }

    final payload = {
      'receiver_id': receiverId,
      'body': cleanMessage, // “body” i stedet for “message”
      'subject': cleanSubject,
      if (replyTo != null) 'reply_to': int.tryParse(replyTo.toString()),
    };

    final response = await _post('/messages', payload);
    _handleVoidResponse(response, successCode: 200);
  }

  static Future<void> markThreadAsRead(String threadId) async {
    final response = await _patch('/messages/thread/$threadId/read', {});
    _handleVoidResponse(response, successCode: 204);
  }

  static Future<void> deleteThread(String threadId) async {
    final response = await _delete('/messages/thread/$threadId');
    _handleVoidResponse(response, successCode: 204);
  }

  static Future<List<Map<String, dynamic>>> fetchRecipients() async {
    final response = await _get('/messages/recipients');
    return _handleListResponse(response);
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 16) Aktiviteter (Activity Labels)
  //     • Hent alle (eller filtreret): GET /api/activity-labels?patient_id=<id>
  //     • Opret ny:             POST /api/activity-labels
  //     • Slet eller andet kan udvides
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchActivities(String patientId) async {
    final response = await _get('/activities?patient_id=$patientId');
    return _handleListResponse(response);
  }

  static Future<void> addActivityEvent({
    required String patientId,
    required String eventType,
    required String note,
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) async {
    final payload = {
      'patient_id': patientId,
      'event_type': eventType,
      'note': note,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
    };
    final response = await _post('/activities', payload);
    _handleVoidResponse(response, successCode: 200);
  }

  static Future<void> deleteActivity(int activityId,
      {required String userId}) async {
    final response = await _delete('/activity-labels/$activityId?user_id=$userId');
    _handleVoidResponse(response, successCode: 200);
  }

  static Future<void> addActivityLabel(String label) async {
    final payload = {'label': label};
    final response = await _post('/activity-labels', payload);
    _handleVoidResponse(response, successCode: 200);
  }

  static Future<List<String>> fetchActivityLabels() async {
    final response = await _get('/activity-labels');
    return List<String>.from(jsonDecode(response.body));
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 17) 🌐 Offline‐synkronisering & fejl‐log (Error Logs)
  //     POST /api/error-logs
  //─────────────────────────────────────────────────────────────────────────────
  static Future<void> postSyncErrorLog(Map<String, dynamic> data) async {
    final headers = await _authHeaders(); // Hvis du vil bruge auth, ellers bare Content-Type
    await http.post(
      Uri.parse('$baseUrl/api/error-logs'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 18) Sensor‐relaterede POST‐endpoints
  //     • Opret batteristatus: POST /api/patient-battery-status
  //     • Opret lysdata:       POST /api/patient-light-data
  //     • Opslag af sensor‐id:  GET  /api/get-sensor-id?device_serial=<serial>
  //     • Registrér sensor‐brug: POST /api/register-sensor-use
  //     • Afslut sensor‐brug:    POST /api/end-sensor-use
  //─────────────────────────────────────────────────────────────────────────────
  static Future<String?> registerSensorUse({
    required String patientId,
    required String deviceSerial,
    required String jwt,
  }) async {
    final url = Uri.parse('$baseUrl/api/sensor/register-sensor-use');

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
      return body["sensor_id"].toString();
    } else {
      print(
          "❌ Fejl ved sensor‐registrering: ${response.statusCode} ${response.body}");
      return null;
    }
  }

  static Future<bool> sendBatteryStatus({
    required String patientId,
    required int sensorId,
    required int batteryLevel,
    required String jwt,
  }) async {
    final url = Uri.parse("$baseUrl/api/sensor/patient-battery-status");

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Batteriniveau sendt til backend");
      return true;
    } else {
      print("❌ Fejl ved batteri-API: ${response.body}");
      return false;
    }
  }


  static Future<int?> getSensorIdFromDevice(
      String deviceSerial, String jwt) async {
    final url = Uri.parse(
        '$baseUrl/api/sensor/get-sensor-id?device_serial=$deviceSerial');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['sensor_id'];
    } else {
      print("❌ Kunne ikke hente sensor_id: ${response.statusCode}");
      return null;
    }
  }

  static Future<bool> sendLightData(
      Map<String, dynamic> data,
      String jwt,
      ) async {
    final url = Uri.parse("$baseUrl/api/sensor/patient-light-data");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      print("✅ Lys data sendt succesfuldt");
      return true;
    } else {
      print("❌ Fejl ved sendLightData: ${response.statusCode} ${response.body}");
      return false;
    }
  }



  static Future<void> endSensorUse({
    required String patientId,
    required int sensorId,
    required String jwt,
    String status = "manual",
  }) async {
    final url = Uri.parse('$baseUrl/api/sensor/end-sensor-use');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'patient_id': patientId,
        'sensor_id': sensorId,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Sensor‐brug afsluttet i backend");
    } else {
      print("❌ Fejl ved end-sensor-use: ${response.statusCode} ${response.body}");
    }
  }

  static Future<bool> sendSensorLog(
      Map<String, dynamic> data,
      String jwt,
      ) async {
    // Hvis der IKKE er et 'ended_at', så antager vi, at du vil åbne en ny log
    if (!data.containsKey('ended_at') || data['ended_at'] == null) {
      final url = Uri.parse('$baseUrl/api/sensor/register-sensor-use');
      final body = {
        'patient_id': data['patient_id'],
        'device_serial': data['device_serial'],
      };
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ sendSensorLog (register) fejlede: ${response.statusCode} ${response.body}');
        return false;
      }
    }
    // Ellers lukker vi den eksisterende log
    else {
      final url = Uri.parse('$baseUrl/api/sensor/end-sensor-use');
      final body = {
        'patient_id': data['patient_id'],
        'sensor_id': data['sensor_id'],
        'status': data['status'] ?? 'manual',
      };
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ sendSensorLog (end) fejlede: ${response.statusCode} ${response.body}');
        return false;
      }
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 19) Chore‐type & beregninger
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchChronotypes() async {
    final response = await _get('api/chronotypes');
    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> fetchChronotype(
      String typeKey) async {
    final response = await _get('api/chronotypes/$typeKey');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> fetchChronotypeByScore(
      int score) async {
    final response = await _get('api/chronotypes/by-score/$score');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> fetchChronotypeByScoreFromBackend(
      int customerId) async {
    final response = await _get('/customers/$customerId');
    final customer = _handleResponse(response);

    final score = customer['rmeq_score'];
    if (score == null) {
      throw Exception('rMEQ‐score mangler for bruger $customerId');
    }

    return fetchChronotypeByScore(score);
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 20) Kunderegistrering
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkEmailAvailability(
      String email) async {
    final response = await _post('/check-email', {'email': email});
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    int? birthYear,
    String? gender,
    String? chronotypeKey,
    required List<String> answers,
    required Map<String, int> questionScores,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      if (birthYear != null) 'birth_year': birthYear,
      if (gender != null) 'gender': gender,
      if (chronotypeKey != null) 'chronotype_key': chronotypeKey,
      'answers': answers,
      'question_scores': questionScores,
    };

    final response = await _post('/customers', payload);
    return _handleResponse(response);
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 21) Gør GET/POST‐metoder tilgængelige uden auth ved behov
  //─────────────────────────────────────────────────────────────────────────────
  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) =>
      _post(endpoint, body);

  static Future<http.Response> patch(
      String endpoint, Map<String, dynamic> body) =>
      _patch(endpoint, body);

  static Future<http.Response> del(String endpoint) => _delete(endpoint);

  /// Når man har brug for at håndtere en “void”‐kode (f.eks. DELETE 204),
  /// kan man kalde denne metode med det konkrete response‐objekt:
  static void handleVoidResponse(
      http.Response response, {
        required int successCode,
      }) =>
      _handleVoidResponse(response, successCode: successCode);
}
