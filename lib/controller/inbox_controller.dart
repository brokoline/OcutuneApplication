import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/services/message_service.dart';
import 'package:ocutune_light_logger/models/messages_model.dart';

enum InboxType { patient, clinician }

class InboxController extends ChangeNotifier {
  final InboxType inboxType;

  InboxController({required this.inboxType});

  List<Message> _allMessages = [];
  List<Message> get messages => _filteredMessages();

  bool isLoading = false;
  String? error;

  Future<void> fetchInbox() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final jwt = await AuthStorage.getTokenPayload();
      final userId = jwt['sub']?.toString();

      if (userId == null) {
        error = 'Bruger-ID mangler.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final raw = await MessageService.fetchMessages(userId);
      raw.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      _allMessages = raw;
    } catch (e) {
      error = '❌ Kunne ikke hente beskeder: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await AuthStorage.getToken();
      final rawId = await AuthStorage.getUserId();
      final userId = rawId?.toString();

      if (token != null && userId != null) {
        final fetched = await MessageService.fetchMessages(userId);
        fetched.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        _allMessages = fetched;
      } else {
        error = 'Bruger-ID eller token mangler.';
      }
    } catch (e) {
      error = '❌ Kunne ikke hente beskeder: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  // Filtrerer beskeder baseret på brugerens rolle
  List<Message> _filteredMessages() {
    return _allMessages.where((msg) {
      switch (inboxType) {
        case InboxType.clinician:
        // Kliniker skal se beskeder, der er TIL klinikeren (senderId != mig)
          return !msg.isMe;
        case InboxType.patient:
        // Patient skal se beskeder, der er FRA patienten (senderId == mig)
          return msg.isMe;
      }
    }).toList();
  }



  Future<void> refresh() async {
    await fetchInbox();
  }
}
