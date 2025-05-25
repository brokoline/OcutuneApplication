import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/models/messages_model.dart';
import '../auth_storage.dart';
import 'api_services.dart';

class MessageService {
  // 📥 Hent indbakke (og map til Message-objekter)
  static Future<List<Message>> fetchMessages(String currentUserId) async {
    try {
      final token = await AuthStorage.getToken();
      final url = Uri.parse('https://ocutune.ddns.net/messages/inbox');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📨 GET /messages/inbox – Status: ${response.statusCode}');
      debugPrint('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;
        return messages
            .map((json) => Message.fromJson(json, currentUserId))
            .toList();
      } else {
        throw Exception('Kunne ikke hente beskeder: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Fejl i fetchMessages(): $e');
      rethrow;
    }
  }

  // 🧵 Hent tråd
  static Future<List<Map<String, dynamic>>> fetchThread(String threadId) async {
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
    required String receiverId,
    required String message,
    String subject = '',
    String? replyTo,
  }) async {
    await ApiService.sendMessage(
      receiverId: receiverId,
      message: message,
      subject: subject,
      replyTo: replyTo,
    );
  }

  // 🗑️ Slet tråd
  static Future<void> deleteThread(String threadId) async {
    await ApiService.deleteThread(threadId);
  }

  // ✅ Marker tråd som læst
  static Future<void> markAsRead(String threadId) async {
    final token = await AuthStorage.getToken();
    final url =
    Uri.parse('https://ocutune.ddns.net/messages/mark_read/$threadId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('📤 Markerer som læst: $threadId – status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Kunne ikke markere som læst');
    }
  }

  // 📇 Hent mulige modtagere (for patienter)
  static Future<List<Map<String, dynamic>>> getRecipients() async {
    return await ApiService.fetchRecipients();
  }
}
