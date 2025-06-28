import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/services/message_service.dart';
import 'package:ocutune_light_logger/models/messages_model.dart';

enum InboxType { patient, clinician }

class InboxController extends ChangeNotifier {
  final InboxType inboxType;

  String? _myUserId;
  List<Message> _allMessages = [];

  InboxController({required this.inboxType});

  bool isLoading = false;
  String? error;

  List<Message> get messages => _filteredMessages();

  Future<void> fetchInbox() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final jwt = await AuthStorage.getTokenPayload();
      final userId = jwt['sub']?.toString();
      _myUserId = userId;

      if (userId == null) {
        error = 'Bruger-ID mangler.';
      } else {
        final raw = await MessageService.fetchMessages(userId);
        raw.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        _allMessages = raw;
      }
    } catch (e) {
      error = 'Kunne ikke hente beskeder: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final rawId = await AuthStorage.getUserId();
      final userId = rawId?.toString();
      _myUserId = userId;

      if (userId != null) {
        final fetched = await MessageService.fetchMessages(userId);
        fetched.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        _allMessages = fetched;
      } else {
        error = 'Bruger-ID eller token mangler.';
      }
    } catch (e) {
      error = 'Kunne ikke hente beskeder: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  List<Message> _filteredMessages() {
    if (_myUserId == null) return [];

    // Vis alle beskeder, hvor bruger er enten afsender eller modtager
    return _allMessages.where((msg) {
      return msg.senderId == _myUserId || msg.receiverId == _myUserId;
    }).toList();
  }

  Future<void> refresh() async {
    await fetchInbox();
  }
}
