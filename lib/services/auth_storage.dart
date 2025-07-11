import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/api_services.dart';
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
        return {};
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        print('Token format er ugyldigt (dele: ${parts.length})');
        return {};
      }

      final payloadBase64 = base64.normalize(parts[1]);
      final payloadString = utf8.decode(base64.decode(payloadBase64));
      final Map<String, dynamic> payload = json.decode(payloadString);

      print("Login info gemt i SharedPreferences");
      return payload;
    } catch (e) {
      print('Kunne ikke parse JWT payload: $e');
      return {};
    }
  }

  static Future<void> saveLogin({
    required String id,
    required String role,
    required String token,
    required String simUserId,
    int? customerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    await prefs.setString('user_role', role);
    await prefs.setString('sim_userid', simUserId);
    await prefs.setString('jwt_token', token);

    if (customerId != null) {
      await prefs.setInt('customerId', customerId);
      print('Gemte customerId = $customerId');
    }

    print('Login info gemt i SharedPreferences');
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

  static Future<void> setCustomerId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customerId', id);
  }

  static Future<int?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('customerId');
  }

  static Future<void> saveCustomerProfile({
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_first_name', firstName);
    await prefs.setString('customer_last_name', lastName);
  }

  static Future<String> getCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getString('customer_first_name') ?? '';
    final last  = prefs.getString('customer_last_name')  ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Kunde' : name;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }


  static Future<String?> getUserRole() async {
    final payload = await getTokenPayload();
    final pretty = payload['pretty_role'] as String?;
    if (pretty != null && pretty.isNotEmpty) {
      return pretty;
    }
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


  static Future<void> logoutCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customerId');
    await prefs.remove('customer_first_name');
    await prefs.remove('customer_last_name');
  }

  static const _lastDeviceKey = 'last_connected_device';

  static Future<void> setLastConnectedDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, deviceId);
  }

  static Future<String?> getLastConnectedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDeviceKey);

  }

  static Future<void> saveSensorIdForDevice(
      String deviceSerial,
      String sensorId,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sensorId_$deviceSerial', sensorId);
  }

   static Future<String?> getSensorIdForDevice(
      String deviceSerial,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString('sensorId_$deviceSerial');
    if (local != null) {
      return local;
    }


    final jwt = await getToken();
    if (jwt == null) return null;

    final int? remoteId =
    await ApiService.getSensorIdFromDevice(deviceSerial, jwt);
    if (remoteId != null) {
      final sid = remoteId.toString();
      await prefs.setString('sensorId_$deviceSerial', sid);
      return sid;
    }

    return null;
  }
}







