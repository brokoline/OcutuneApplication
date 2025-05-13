import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static Future<void> saveLoggedInUser({
    required int id,
    required String role,
    required String name,
    required String simUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', name);
    await prefs.setString('sim_userid', simUserId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<String?> getSimUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sim_userid');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
