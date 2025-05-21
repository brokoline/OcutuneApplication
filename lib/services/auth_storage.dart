import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, dynamic>> getTokenPayload() async {
    final token = await getToken();
    if (token == null) throw Exception('JWT token mangler');

    final payloadBase64 = token.split('.')[1];
    final normalized = base64.normalize(payloadBase64);
    final payload = utf8.decode(base64.decode(normalized));

    return json.decode(payload);
  }

  // Gem token og rolle ved login
  static Future<void> saveLogin({
    required int id,
    required String role,
    required String token,
    required String simUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await prefs.setString('user_role', role);
    await prefs.setString('sim_userid', simUserId);
    await prefs.setString('jwt_token', token);
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

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
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

