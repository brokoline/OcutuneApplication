import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/models/messages_model.dart';
import '../auth_storage.dart';
import 'api_services.dart';

class MessageService {
  static Future<List<Message>> fetchMessages(String currentUserId) async {
    try {
      final token = await AuthStorage.getToken();
      final url = Uri.parse('https://ocutune2025.ddns.net/messages/inbox');

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

  static Future<List<Map<String, dynamic>>> fetchThread(String threadId) async {
    debugPrint('📨 Henter tråd $threadId');
    final thread = await ApiService.fetchThread(threadId);
    debugPrint('🧵 Tråd #$threadId – ${thread.length} beskeder');

    for (var msg in thread) {
      debugPrint('🧾 ${msg['sender_name']} → ${msg['receiver_name']}');
    }

    return thread;
  }

  static Future<void> send({
    required String receiverId,
    required String message,
    String subject = '',
    String? replyTo,
  }) async {
    final trimmedMessage = message.trim();
    final trimmedSubject = subject.trim().isNotEmpty ? subject.trim() : 'Uden emne';

    if (trimmedMessage.isEmpty) {
      throw Exception('Besked må ikke være tom');
    }

    final payload = {
      'receiver_id': receiverId,
      'message': trimmedMessage,
      'subject': trimmedSubject,
      if (replyTo != null) 'reply_to': replyTo,
    };

    print('📤 Sender besked med payload: $payload');

    final response = await ApiService.post('/messages/send', payload);
    ApiService.handleVoidResponse(response, successCode: 200);
  }

  static Future<void> deleteThread(String threadId) async {
    final response = await ApiService.del('/messages/thread/$threadId');
    ApiService.handleVoidResponse(response, successCode: 204);
  }

  static Future<void> markAsRead(String threadId) async {
    final response = await ApiService.patch('/messages/thread/$threadId/read', {});
    ApiService.handleVoidResponse(response, successCode: 204);
  }

  static Future<List<Map<String, dynamic>>> getRecipients() async {
    return await ApiService.fetchRecipients();
  }
}
