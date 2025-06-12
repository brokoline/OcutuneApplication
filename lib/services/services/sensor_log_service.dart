import 'package:ocutune_light_logger/services/auth_storage.dart';

import 'api_services.dart';

class SensorLogService {
  static String? _jwt;

  static Future<void> init() async {
    _jwt = await AuthStorage.getToken();
  }

  static Future<void> logSensorEvent({
    required String sensorId,
    required String patientId,
    required String eventType,
    String? status,
    bool isAutoReconnect = false,
    String? errorMessage,
  }) async {
    try {
      if (_jwt == null) await init();

      final response = await ApiService.postSensorLog(
        jwt: _jwt!,
        data: {
          'sensor_id': sensorId,
          'patient_id': patientId,
          'event_type': eventType,
          'status': status ?? _determineDefaultStatus(eventType),
          'is_auto_reconnect': isAutoReconnect,
          if (errorMessage != null) 'error_message': errorMessage,
        },
      );

      if (!response['success']) {
        throw Exception('API returned error: ${response['error']}');
      }
    } catch (e) {
      print('‼️ Sensor log fejl: $e');
    }
  }

  static String _determineDefaultStatus(String eventType) {
    switch (eventType) {
      case 'connected':
        return 'active';
      case 'disconnected':
        return 'manual';
      case 'error':
        return 'failed';
      default:
        return 'unknown';
    }
  }
}