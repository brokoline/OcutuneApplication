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

        // sortér nyeste øverst
        fetched.sort((a, b) => b.sentAt.compareTo(a.sentAt));

        _allMessages = fetched;
      } else {
        error = 'Bruger-ID eller token mangler.';
      }
    } catch (e) {
      error = 'Kunne ikke hente beskeder.';
    }

    isLoading = false;
    notifyListeners();
  }

  List<Message> _filteredMessages() {
    return _allMessages.where((msg) {
      return inboxType == InboxType.clinician ? msg.isMe : !msg.isMe;
    }).toList();
  }
}
