import 'package:flutter/cupertino.dart';

import 'api_services.dart';

class MessageService {
  // 📥 Hent indbakke
  static Future<List<Map<String, dynamic>>> fetchInbox() async {

    final inbox = await MessageService.fetchInbox();
    debugPrint('📥 Antal beskeder i indbakke: ${inbox.length}');
    for (var msg in inbox) {
      debugPrint('🧾 Tråd: ${msg['thread_id']} – Afsender: ${msg['sender_name']} (${msg['sender_id']}) → Modtager: ${msg['receiver_name']} (${msg['receiver_id']})');
    }

    return await ApiService.fetchInbox();
  }

  // 🧵 Hent tråd
  static Future<List<Map<String, dynamic>>> fetchThread(int threadId) async {
    debugPrint('📨 Henter tråd $threadId');
    final thread = await ApiService.fetchThread(threadId);
    debugPrint('🧵 Tråd #$threadId – ${thread.length} beskeder');

    for (var msg in thread) {
      debugPrint('🧾 ${msg['sender_name']} → ${msg['receiver_name']}');
    }

    return thread;
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

