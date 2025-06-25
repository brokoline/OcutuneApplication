// lib/services/services/api_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/models/customer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/daily_light_summary_model.dart';
import '../../models/light_data_model.dart';
import '../../models/meq_survey_model.dart';
import '../../models/patient_model.dart';
import '../../models/rmeq_chronotype_model.dart';
import '../auth_storage.dart';


// Simpel tuple‐klasse til at returnere både Customer og ChronotypeModel
class Pair<A, B> {
  final A first;
  final B second;
  Pair(this.first, this.second);
}


// Base URL for alle API‐kald
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
  // 2) Helper: Returner headers med JWT‐token og uden auth
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null) throw Exception('Mangler token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET UDEN Authorization‐header – kun Content‐Type
  static Future<http.Response> _getNoAuth(String endpoint) {
    return http.get(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
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
  // 4) Helper: HTTP POST (indsætter "/api" foran endpointet) og uden headers
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

  // POST UDEN Authorization‐header – kun Content-Type
  static Future<http.Response> _postNoAuth(
      String endpoint, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
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
// 7) Helper: HTTP PUT (indsætter "/api" foran endpointet)
//─────────────────────────────────────────────────────────────────────────────
  static Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.put(
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
  // 11) HELPER metode til at tilgå links
  //─────────────────────────────────────────────────────────────────────────────

  static Future<void> launchUrl(String url) async {
  }


  //─────────────────────────────────────────────────────────────────────────────
  // 10) Al lysdata for én patient (og mock for alle kunder), og daglige, ugentlige og månedlige lysdata
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


  static Future<List<DailyLightSummary>> fetchWeeklyLightData({
    required String patientId,
  }) async {
    final response = await _get('/patients/$patientId/lightdata/weekly');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList
          .map((item) => DailyLightSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      return <DailyLightSummary>[];
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized: Manglende eller ugyldig token");
    } else {
      throw Exception("Serverfejl: ${response.statusCode}");
    }
  }


  static Future<List<DailyLightSummary>> fetchMonthlyLightData({
    required String patientId,
  }) async {
    final response = await _get("/patients/$patientId/lightdata/monthly");
    final rawList = _handleListResponse(response);
    return rawList
        .map((jsonMap) => DailyLightSummary.fromJson(jsonMap))
        .toList();
  }


  // Kunde mock data af Patient data
  static Future<List<LightData>> fetchCustomerDailyLightData({
    required String customerToken,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/customer/lightdata/daily'),
    );
    if (response.statusCode != 200) {
      throw Exception('Fejl: ${response.statusCode}');
    }
    final List<dynamic> jsonList = json.decode(response.body)['data'];
    return jsonList.map((e) => LightData.fromJson(e as Map<String, dynamic>)).toList();
  }


  static Future<List<LightData>> fetchCustomerWeeklyLightData({
    required String customerToken,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/customer/lightdata/weekly'),
    );
    if (response.statusCode != 200) {
      throw Exception('Fejl: ${response.statusCode}');
    }
    final List<dynamic> jsonList = json.decode(response.body)['data'];
    return jsonList.map((e) => LightData.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<LightData>> fetchCustomerMonthlyLightData({
    required String customerToken,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/customer/lightdata/monthly'),
    );
    if (response.statusCode != 200) {
      throw Exception('Fejl: ${response.statusCode}');
    }
    final List<dynamic> jsonList = json.decode(response.body)['data'];
    return jsonList.map((e) => LightData.fromJson(e as Map<String, dynamic>)).toList();
  }




  //─────────────────────────────────────────────────────────────────────────────
  // 11) Authentication (Login) – gemmer JWT i SharedPreferences
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> simulatedLogin(
      String userId,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/mitid/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sim_userid': userId, 'sim_password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      // 1) Gem token
      await prefs.setString('jwt_token', data['token'] as String);

      // 2) Gem rolle (bør være enten "clinician" eller "patient")
      final String role = data['role'] as String;
      await prefs.setString('user_role', role);

      // 3) Gem bruger-ID (identity), som vi senere kan bruge til permission-checks
      //    Bemærk: data['id'] kan være en int eller en streng; konverter altid til streng.
      final String idString = data['id'].toString();
      await prefs.setString('user_id', idString);

      return data;
    } else {
      throw Exception('Login fejlede: HTTP ${response.statusCode}');
    }
  }


  static Future<Map<String, dynamic>> customerLogin(
      String email,
      String password,
      ) async {
    final url = Uri.parse("$_baseUrl/api/auth/customer/login");
    final headers = <String, String>{
      "Content-Type": "application/json",
    };
    final body = jsonEncode({
      "email": email,
      "password": password,
    });

    final response = await http.post(url, headers: headers, body: body);

    // Prøv at parse JSON‐svar
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && decoded["success"] == true) {
      return {
        "success": true,
        "token": decoded["token"],
        "user": decoded["user"],
      };
    } else {
      return {
        "success": false,
        "message": decoded["message"] ?? "Ukendt fejl ved login.",
      };
    }
  }

  /// GET /api/customer/profile
  static Future<Pair<Customer, ChronotypeModel?>> fetchCustomerProfile() async {
    // 1) Grab token
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception("Ingen token tilgængelig – prøv at logge ind først");
    }

    // 2) Call profile endpoint
    final uri = Uri.parse('$_baseUrl/api/customer/profile');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('DEBUG: GET $uri → ${response.statusCode}');
    print('DEBUG: body: ${response.body}');

    // 3) Handle result
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      // ensure success flag
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? "Uventet fejl ved hent af profil");
      }

      // unwrap the “data” envelope
      final data     = decoded['data'] as Map<String, dynamic>;

      // parse customer
      final customer = Customer.fromJson(data);

      // parse optional chronotype_details
      ChronotypeModel? chronoModel;
      final chronoJson = data['chronotype_details'];
      if (chronoJson != null) {
        chronoModel = ChronotypeModel.fromJson(
            chronoJson as Map<String, dynamic>
        );
      }

      return Pair(customer, chronoModel);
    }

    // non‐200
    if (response.statusCode == 401) {
      throw Exception("Uautoriseret (401) – tjek token");
    } else if (response.statusCode == 404) {
      throw Exception("Endpoint ikke fundet (404) – tjek URL");
    } else {
      throw Exception(
          "Serverfejl ved hentning af profil: ${response.statusCode}"
      );
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

  // GET kliniker profil/rolle
  static Future<Map<String, dynamic>?> fetchClinicianProfile() async {
    final token = await AuthStorage.getToken();
    if (token == null) return null;

    final url = Uri.parse('$_baseUrl/api/clinician/clinicianprofile');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
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

  static Future<List<Map<String, dynamic>>> fetchThread(String threadId) async {
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

    // Bemærk: Vi skal kalde POST /api/messages/send (ikke blot /api/messages)
    final payload = <String, dynamic>{
      'receiver_id': receiverId,
      'message': cleanMessage,    // her hedder feltet “message” i backend
      'subject': cleanSubject,
      if (replyTo != null) 'reply_to': int.tryParse(replyTo.toString()),
    };

    final response = await _post('/messages/send', payload);
    // Flask returnerer 200 + { "status": "Besked sendt" }, så vi kan bare håndtere som “void”
    _handleVoidResponse(response, successCode: 200);
  }

  // Marker en enkelt besked som læst/ulæst. (PATCH på besked‐ID)
  // Hvis du i stedet vil markere hele tråden som læst, skal du lave en tilsvarende
  // PATCH‐endpoint på backend. Her viser jeg, hvordan du rammer PATCH /api/messages/<messageId>.
  static Future<void> updateSingleMessage({
    required String messageId,
    bool? read,
    String? newSubject,
    String? newMessageText,
  }) async {

    final data = <String, dynamic>{};
    if (read != null) data['read'] = read;
    if (newSubject != null) data['subject'] = newSubject.trim();
    if (newMessageText != null) data['message'] = newMessageText.trim();

    if (data.isEmpty) {
      throw Exception('Ingen felter angivet til opdatering');
    }

    final response = await _patch('/messages/$messageId', data);
    _handleVoidResponse(response, successCode: 200);
  }

  /// Sletter hele tråden (flytter til deleted_messages og sletter fra messages)
  static Future<void> deleteThread(String threadId) async {
    final response = await _delete('/messages/thread/$threadId');
    _handleVoidResponse(response, successCode: 204);
  }

  /// Henter mulige modtagere (kliniker → patienter, patient → klinikere)
  static Future<List<Map<String, dynamic>>> fetchRecipients() async {
    final response = await _get('/messages/recipients');
    return _handleListResponse(response);
  }

  /// (Ekstra) Hvis du vil markere hele en tråd som læst på backend, kan du lægge
  // et nyt endpoint ind i Flask som PATCH /api/messages/thread/<threadId>/read,
  // og så ramme det her. Jeg viser eksemplet, men husk at tilsvarende tilføje
  // koden i `message_routes.py` for at opdatere alle beskeder i tråden.
  static Future<void> markThreadAsRead(String threadId) async {
    final response = await _patch('/api/messages/thread/$threadId/read', {});
    _handleVoidResponse(response, successCode: 204);
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 16) Aktiviteter (Activity Labels)
  //     • Hent alle (eller filtreret): GET /api/activity-labels?patient_id=<id>
  //     • Opret ny:             POST /api/activity-labels
  //     • Slet eller andet kan udvides
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<String>> fetchActivityLabels(String patientId) async {
    final response = await _get("/activity-labels?patient_id=$patientId");
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<String>();
    } else {
      throw Exception("HTTP ${response.statusCode} – ${response.reasonPhrase}");
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Opretter et nyt activity‐label for patienten
  // POST /api/activity-labels/activity-labels
  // ──────────────────────────────────────────────────────────────────────────────
  static Future<void> addActivityLabel({
    required String patientId,
    required String label,
  }) async {
    final payload = {
      'patient_id': patientId,
      'label': label,
    };
    final response = await _post("/activity-labels", payload);
    _handleVoidResponse(response, successCode: 201);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Henter alle patient‐events (activities) for en given patient
  // GET  /api/activities/activities?patient_id=<id>
  // ──────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchActivities(String patientId) async {
    final response = await _get("/activities?patient_id=$patientId");
    return _handleListResponse(response);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Opretter et nyt patient‐event (activity)
  // POST /api/activities/activities
  // ──────────────────────────────────────────────────────────────────────────────
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
    final response = await _post("/activities", payload);
    _handleVoidResponse(response, successCode: 201);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Sletter et patient‐event (activity) med det ID
  // DELETE /api/activities/activities/<activityId>?user_id=<id>
  // ──────────────────────────────────────────────────────────────────────────────
  static Future<void> deleteActivity(int activityId, { required String userId }) async {
    final response = await _delete("/activities/$activityId?user_id=$userId");
    // Flask returnerer 204 No Content på succes
    _handleVoidResponse(response, successCode: 204);
  }


  //─────────────────────────────────────────────────────────────────────────────
  // 17) Customer‐events (Activities) under /api/customer
  //─────────────────────────────────────────────────────────────────────────────
  /// 1) Henter alle customer‐event labels
  ///    GET /api/customer/activities/labels?customer_id=$customerId
  static Future<List<String>> fetchCustomerActivityLabels(String customerId) async {
    final response = await _get("/customer/activities/labels?customer_id=$customerId");
    if (response.statusCode != 200) {
      throw Exception('Kunne ikke hente labels: ${response.statusCode}');
    }

    dynamic decoded = json.decode(response.body);
    if (decoded is String) decoded = json.decode(decoded);
    if (decoded is Map && decoded['labels'] is List) decoded = decoded['labels'];
    if (decoded is! List) {
      throw Exception('Uventet format for customer labels: ${decoded.runtimeType}');
    }

    return decoded.map<String>((e) {
      if (e is Map && e['label'] is String) return e['label'] as String;
      return e as String;
    }).toList();
  }

  /// 2) Henter alle customer‐events (activities)
  ///    GET /api/customer/activities?customer_id=<id>
  static Future<List<Map<String, dynamic>>> fetchCustomerActivities(String customerId) async {
    final response = await _get("/customer/activities?customer_id=$customerId");
    if (response.statusCode != 200) {
      throw Exception('Kunne ikke hente aktiviteter: ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    }
    throw Exception('Uventet format for customer activities');
  }

  /// 3) Opretter et nyt customer‐event (activity)
  ///    POST /api/customer/activities
  static Future<void> addCustomerActivityEvent({
    required String customerId,
    required String eventType,
    required String note,
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) async {
    final payload = {
      'customer_id':      customerId,
      'event_type':       eventType,
      'note':             note,
      'start_time':       startTime,
      'end_time':         endTime,
      'duration_minutes': durationMinutes,
    };
    final response = await _post("/customer/activities", payload);
    if (response.statusCode != 201) {
      throw Exception('Kunne ikke oprette aktivitet: ${response.statusCode}');
    }
  }

  /// 4) Sletter et customer‐event (activity)
  ///    DELETE /api/customer/activities/<activityId>?customer_id=<id>
  static Future<void> deleteCustomerActivity(
      int activityId,
      String customerId, {
        /// Hvad HTTP-kode vi forventer på succes (default 204)
        int successCode = 204,
      }) async {
    final response = await _delete(
      "/customer/activities/$activityId?customer_id=$customerId",
    );
    _handleVoidResponse(response, successCode: successCode);
  }

  /// 5) Tilføjer en ny custom‐label til customer
  ///    POST /api/customer/activities/labels
  static Future<void> addCustomerActivityLabel({
    required String customerId,
    required String label,
  }) async {
    final payload = {
      'customer_id': customerId,
      'label':       label,
    };
    final response = await _post("/customer/activities/labels", payload);
    if (response.statusCode != 201) {
      throw Exception('Kunne ikke tilføje label: ${response.statusCode}');
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 17) 🌐 Offline‐synkronisering & fejl‐log (Error Logs)
  //     POST /api/error-logs
  //─────────────────────────────────────────────────────────────────────────────
  static Future<void> postSyncErrorLog(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
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

  static Future<Map<String, dynamic>> postSensorLog({
    required String jwt,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensor/log'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

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
  // 19) RMEQ Chronotype & beregninger
  //─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchChronotypes() async {
    try {
      final response = await _getNoAuth('/api/chronotypes');
      print('[fetchChronotypes] status: ${response.statusCode}');
      print('[fetchChronotypes] body:   ${response.body}');

      return _handleListResponse(response);
    } catch (e) {
      print('[fetchChronotypes] FEJL: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchChronotype(String typeKey) async {
    try {
      final response = await _getNoAuth('/api/chronotypes/$typeKey');

      print('[fetchChronotype] status: ${response.statusCode}');
      print('[fetchChronotype] body:   ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('[fetchChronotype] FEJL: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> fetchChronotypeByScore(int score) async {
    try {
      final response =
      await _getNoAuth('/api/chronotypes/rmeq-by-score/$score');

      print('[fetchByScore] status: ${response.statusCode}');
      print('[fetchByScore] body:   ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('[fetchByScore] FEJL: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> fetchChronotypeByScoreFromBackend(
      int customerId) async {
    try {
      final calcResponse =
      await _postNoAuth('/api/chronotypes/calculate-rmeq-score/$customerId', {});

      print('[calcScore] status: ${calcResponse.statusCode}');
      print('[calcScore] body:   ${calcResponse.body}');

      if (calcResponse.statusCode != 200) {
        throw Exception(
            "HTTP ${calcResponse.statusCode}: ${calcResponse.reasonPhrase} → ${calcResponse.body}");
      }

      final calcData = jsonDecode(calcResponse.body) as Map<String, dynamic>;
      final score = calcData['remq_score'];
      if (score == null) {
        throw Exception('Ingen remq_score i svar fra server (BODY: ${calcResponse.body})');
      }

      // 4b) Hent cronotype ud fra den beregnede score (igen uden token):
      return await fetchChronotypeByScore(score as int);
    } catch (e) {
      print('[fetchChronotypeByScoreFromBackend] FEJL: $e');
      rethrow;
    }
  }

  //─────────────────────────────────────────────────────────────────────────────
  // 20) Kunderegistrering + choices/answers + skift password + delete customer
  // GET, POST, DELETE
  //─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkEmailAvailability(
      String email) async {
    final response = await _post('/auth/check-email', {'email': email});
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
      if (birthYear != null)    'birth_year': birthYear,
      if (gender != null)       'gender': gender,
      if (chronotypeKey != null)'chronotype': chronotypeKey,
      'answers': answers,
      'question_scores': questionScores,
    };

    final response = await _post('/api/auth/registerCustomer', payload);
    final body     = _handleResponse(response);

    // ── NYT: gem tokens ─────────────────────────────────────
    final accessToken  = body['access_token']  as String;
    final refreshToken = body['refresh_token'] as String;
    final userJson     = body['user'] as Map<String, dynamic>;

    await AuthStorage.saveLogin(
      id:        userJson['id'].toString(),
      role:      userJson['role'] as String,
      token:     accessToken,
      simUserId: refreshToken,
    );
    print('✅ Gemte tokens: $accessToken / $refreshToken');

    return body;
  }


  static Future<Map<String, dynamic>> updateCustomerChronotype({
    required String chronotypeKey,
    int? rmeqScore,
  }) async {
    final payload = <String, dynamic>{
      'chronotype': chronotypeKey,
      if (rmeqScore != null) 'rmeq_score': rmeqScore,
    };

    final response = await _put('/customer/profile', payload);
    final body = _handleResponse(response);

    print('✅ Kronotype opdateret til: $chronotypeKey');

    return body;
  }



  static Future<void> deleteCustomer(String id) async {
    final response = await _delete('/customer/delete/$id');
    final body = _handleResponse(response);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Ukendt fejl ved sletning');
    }
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl = 'https://ocutune2025.ddns.net/api';
    final questionsUrl = Uri.parse('$baseUrl/questions?question_id=$questionId');
    final choicesUrl   = Uri.parse('$baseUrl/choices?question_id=$questionId');

    // 1) Hent både spørgsmål og choices parallelt
    final responses = await Future.wait([
      http.get(questionsUrl),
      http.get(choicesUrl),
    ]);

    final qResponse = responses[0];
    final cResponse = responses[1];

    // 2) Tjek begge status‐koder
    if (qResponse.statusCode == 200 && cResponse.statusCode == 200) {
      // 3) Pars det enkelte spørgsmål som Map<String, dynamic>
      final questionJson = jsonDecode(qResponse.body) as Map<String, dynamic>;

      // 4) Pars alle choices som List<Map<String, dynamic>>
      final rawChoices = jsonDecode(cResponse.body) as List<dynamic>;
      final choicesList =
      rawChoices.cast<Map<String, dynamic>>();

      // 5) Byg en scoreMap fra choice_text -> score
      final scoreMap = <String, int>{
        for (var c in choicesList)
          c['choice_text'] as String: c['score'] as int,
      };

      // 6) Returnér netop det, UI’et forventer:
      return {
        'text': questionJson['question_text'] as String,
        'choices': scoreMap.keys.toList(),
        'scores': scoreMap,
      };
    } else {
      // Hvis mindst ét kald fejlede, smid exception
      throw Exception('Kunne ikke hente spørgsmål og/eller valgmuligheder. '
          'StatusQ=${qResponse.statusCode}, StatusC=${cResponse.statusCode}');
    }
  }


  static Future<List<Map<String, dynamic>>> fetchChoices({int? questionId}) async {
    // 1) Byg endpoint‐strengen
    String endpoint = '/choices';
    if (questionId != null) {
      endpoint += '?question_id=$questionId';
    }

    final response = await _getNoAuth(endpoint);


    print('[fetchChoices] GET https://ocutune2025.ddns.net/api$endpoint → ${response.statusCode}');
    print('[fetchChoices] body: ${response.body}');


    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Kunne ikke hente choices: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> submitAnswer({
    required int customerId,
    required int questionId,
    required int choiceId,
    required String answerText,
    required String questionTextSnap,
  }) async {
    final payload = {
      'customer_id': customerId,
      'question_id': questionId,
      'choice_id': choiceId,
      'answer_text': answerText,
      'question_text_snap': questionTextSnap,
    };
    final response = await _postNoAuth('/submit_answer', payload);
    print('[submitAnswer] status: ${response.statusCode}, body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Kunne ikke indsende svar: ${response.statusCode}');
    }
  }


  //─────────────────────────────────────────────────────────────────────────────
  // 22) Kunderuter
  //─────────────────────────────────────────────────────────────────────────────

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String jwtToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/customer/profile/changepassword');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to change password: ${response.body}');
    }
  }


  //─────────────────────────────────────────────────────────────────────────────
  // 2?) MEQ survery relaterede ruter
  //─────────────────────────────────────────────────────────────────────────────

  // Henter spørgsmål + choices
  static Future<List<MeqQuestion>> fetchMeqQuestions() async {
    final uri = Uri.parse('$_baseUrl/questions');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Fejl ved hentning: ${resp.statusCode}');
    }
    final List jsonList = jsonDecode(resp.body) as List;
    return jsonList.map((e) => MeqQuestion.fromJson(e)).toList();
  }

  // Henter eksisterende svar for en deltager
  static Future<List<MeqAnswer>> fetchMeqAnswers(int participantId) async {
    final uri = Uri.parse('$_baseUrl/participants/$participantId/answers');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Fejl ved hentning: ${resp.statusCode}');
    }
    final List jsonList = jsonDecode(resp.body) as List;
    return jsonList.map((e) => MeqAnswer.fromJson(e)).toList();
  }

  // Poster nye svar
  static Future<bool> postMeqAnswers({
    required int participantId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final uri = Uri.parse('$_baseUrl/answers');
    final body = jsonEncode({
      'participant_id': participantId,
      'answers': answers,
    });
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception('Fejl ved indsending: ${resp.statusCode}');
    }
    final jsonResp = jsonDecode(resp.body);
    return jsonResp['status'] == 'OK';
  }

  // Overskriv eksisterende svar via PUT /answers
  // Returnerer den nye `meq_score`
  Future<int> updateAnswers({
    required String participantId,
    required List<Map<String,int>> answers,
  }) async {
    final uri = Uri.parse('$_baseUrl/answers');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'participant_id': participantId,
        'answers':        answers,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Kunne ikke opdatere svar (PUT): ${response.statusCode} ${response.body}'
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['meq_score'] ?? 0) as int;
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
  static void handleVoidResponse(
      http.Response response, {
        required int successCode,
      }) =>
      _handleVoidResponse(response, successCode: successCode);
}
