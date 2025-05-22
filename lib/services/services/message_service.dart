import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../auth_storage.dart';
import 'api_services.dart';

class MessageService {
  // 📥 Hent indbakke
  static Future<List<Map<String, dynamic>>> fetchInbox() async {
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

      print('📨 Kaldt: GET /messages/inbox');
      print('📥 Statuskode: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final messages = json['messages'] as List;
        return List<Map<String, dynamic>>.from(messages);
      } else {
        throw Exception('Kunne ikke hente beskeder: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fejl i fetchInbox(): $e');
      rethrow;
    }
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
    final token = await AuthStorage.getToken();
    final url = Uri.parse('https://ocutune.ddns.net/messages/mark_read/$threadId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📤 Markerer som læst: $threadId – status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Kunne ikke markere som læst');
    }
  }


  // 📇 Hent mulige modtagere (for patienter)
  static Future<List<Map<String, dynamic>>> getRecipients() async {
    return await ApiService.fetchRecipients();
  }
}

