import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class AuthStorage {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, dynamic>> getTokenPayload() async {
    try {
      final token = await getToken();

      if (token == null) {
        print('❌ Token mangler i SharedPreferences (getTokenPayload)');
        return {};
      }

      print('🔑 Fundet token: $token');

      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Token format er ugyldigt (dele: ${parts.length})');
        return {};
      }

      final payloadBase64 = base64.normalize(parts[1]);
      final payloadString = utf8.decode(base64.decode(payloadBase64));
      final Map<String, dynamic> payload = json.decode(payloadString);

      print("✅ Login info gemt i SharedPreferences");
      return payload;
    } catch (e) {
      print('❌ Kunne ikke parse JWT payload: $e');
      return {};
    }
  }

  static Future<void> saveLogin({
    required String id,
    required String role,
    required String token,
    required String simUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    await prefs.setString('user_role', role);
    await prefs.setString('sim_userid', simUserId);
    await prefs.setString('jwt_token', token);
    print('✅ Login info gemt i SharedPreferences');
  }


static Future<int?> getPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('patientId');
  }

  static Future<void> setPatientId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('patientId', id);
  }

  static Future<void> saveClinicianProfile({
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clinician_name', '$firstName $lastName');
  }

  static Future<String> getClinicianName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('clinician_name') ?? 'Kliniker Dashboard';
  }

  static Future<void> savePatientProfile({
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patient_first_name', firstName);
    await prefs.setString('patient_last_name', lastName);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }


  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }


  static Future<String?> getSimUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sim_userid');
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getString('patient_first_name') ?? '';
    final last = prefs.getString('patient_last_name') ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : 'Bruger';
  }



  static Future<bool> emailExists(String email) async {
    final url = Uri.parse('https://ocutune2025.ddns.net/api/auth/check-email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        return jsonBody['available'] == false;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }






  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('sim_userid');
    await prefs.remove('patient_first_name');
    await prefs.remove('patient_last_name');
  }
}

