import '../../models/messages_model.dart';
import '../auth_storage.dart';
import 'api_services.dart';

enum UserRole { patient, clinician }

class MessageService {
  static Future<List<Map<String, dynamic>>> fetchInbox(UserRole role) async {
    final rawThreads = role == UserRole.patient
        ? await ApiService.getInboxMessages()
        : await ApiService.getClinicianInboxMessages();

    final jwt = await AuthStorage.getTokenPayload();
    final currentUserId = jwt['id'];

    final Map<int, List<Map<String, dynamic>>> grouped = {};

    for (var msg in rawThreads) {
      final threadId = msg['thread_id'];
      grouped.putIfAbsent(threadId, () => []).add(msg);
    }

    final List<Map<String, dynamic>> result = [];

    for (var threadMsgs in grouped.values) {
      threadMsgs.sort((a, b) =>
      DateTime.tryParse(b['sent_at'])?.compareTo(DateTime.tryParse(a['sent_at']) ?? DateTime.now()) ?? 0);

      final newest = threadMsgs.first;
      final oldest = threadMsgs.last;

      final isSentByMe = oldest['sender_id'] == currentUserId;

      // Fallback til sender_name hvis receiver_name == 'Ukendt'
      final fallbackName = isSentByMe
          ? (oldest['receiver_name'] != null && oldest['receiver_name'] != 'Ukendt'
          ? oldest['receiver_name']
          : oldest['sender_name'])
          : (oldest['sender_name'] ?? 'Ukendt');

      final displayName = '${isSentByMe ? 'Til' : 'Fra'}: $fallbackName';

      result.add({
        ...newest,
        'display_name': displayName,
        'last_message_preview': newest['message'] ?? '',
      });
    }

    return result;
  }



  static Future<List<Message>> fetchThread(
      UserRole role, int threadId, int currentUserId) async {
    final data = role == UserRole.patient
        ? await ApiService.getMessageThreadById(threadId)
        : await ApiService.getClinicianMessageThreadById(threadId);

    return data.map((e) => Message.fromJson(e, currentUserId)).toList();
  }

  static Future<void> send({
    required UserRole senderRole,
    required int receiverId,
    required String message,
    required String subject,
    int? replyTo,
  }) async {
    if (senderRole == UserRole.patient) {
      await ApiService.sendPatientMessage(
        message: message,
        subject: subject,
        replyTo: replyTo,
        clinicianId: receiverId,
      );
    } else {
      await ApiService.sendClinicianMessage(
        message: message,
        subject: subject,
        replyTo: replyTo,
        patientId: receiverId,
      );
    }
  }

  static Future<void> deleteThread(int threadId) async {
    await ApiService.deleteThread(threadId);
  }

  static Future<void> markAsRead(int threadId) async {
    await ApiService.markThreadAsRead(threadId);
  }

  static Future<List<Map<String, dynamic>>> getRecipients(UserRole role) async {
    return role == UserRole.patient
        ? await ApiService.getPatientClinicians()
        : await ApiService.getClinicianPatients();
  }
}
