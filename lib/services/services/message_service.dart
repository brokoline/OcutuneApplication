import 'api_services.dart';

class MessageService {
  // 📥 Hent indbakke
  static Future<List<Map<String, dynamic>>> fetchInbox() async {
    return await ApiService.fetchInbox();
  }

  // 🧵 Hent tråd
  static Future<List<Map<String, dynamic>>> fetchThread(int threadId) async {
    return await ApiService.fetchThread(threadId);
  }

  // ✉️ Send besked
  static Future<void> send({
    required int receiverId,
    required String message,
    String subject = '',
    int? replyTo,
  }) async {
    await ApiService.sendMessage(
      receiverId: receiverId,
      message: message,
      subject: subject,
      replyTo: replyTo,
    );
  }

  // 🗑️ Slet tråd
  static Future<void> deleteThread(int threadId) async {
    await ApiService.deleteThread(threadId);
  }

  // ✅ Marker tråd som læst
  static Future<void> markAsRead(int threadId) async {
    await ApiService.markThreadAsRead(threadId);
  }

  // 📇 Hent mulige modtagere (for patienter)
  static Future<List<Map<String, dynamic>>> getRecipients() async {
    return await ApiService.fetchRecipients();
  }
}

