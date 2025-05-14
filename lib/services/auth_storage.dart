import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  // Gem basale loginoplysninger
  static Future<void> saveLoggedInUser({
    required int id,
    required String role,
    required String simUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await prefs.setString('user_role', role);
    await prefs.setString('sim_userid', simUserId);
  }

  // Gem profiloplysninger for patient
  static Future<void> savePatientProfile({
    required int id,
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('patient_id', id);
    await prefs.setString('patient_first_name', firstName);
    await prefs.setString('patient_last_name', lastName);
  }

  // Hent brugerens ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Hent brugerens rolle (patient / clinician)
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Hent simuleret MitID bruger-ID
  static Future<String?> getSimUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sim_userid');
  }

  // Returnér fulde navn (for patient)
  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getString('patient_first_name') ?? '';
    final last = prefs.getString('patient_last_name') ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : 'Bruger';
  }

  // logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
