import 'package:ocutune_light_logger/services/services/api_services.dart';

class RemoteErrorLogger {
  static Future<void> log({
    required String patientId,
    required String type,
    required String message,
    required String stack,
  }) async {
    try {
      await ApiService.postSyncErrorLog({
        "patient_id": patientId,
        "type": type,
        "message": message,
      });
    } catch (e) {
      print("Kunne ikke sende fejl-log til backend: $e");
    }
  }
}