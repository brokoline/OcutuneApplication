import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/messages_model.dart';
import '../../services/auth_storage.dart';
import '../../services/services/message_service.dart';
import '../../theme/colors.dart';
import 'message_bubble.dart';
import 'reply_input.dart';
import '../confirm_dialog.dart';

class MessageThreadScreen extends StatefulWidget {
  final String threadId;

  const MessageThreadScreen({super.key, required this.threadId});

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  List<Message> _messages = [];
  Message? _original;
  String? _currentUserId;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages({bool scrollToBottom = true}) async {
    try {
      final jwt = await AuthStorage.getTokenPayload();
      _currentUserId = jwt['sub'];

      final raw = await MessageService.fetchThread(widget.threadId);
      print('🧪 raw length: ${raw.length}');
      print('🧪 raw: $raw');

      final parsed = raw.map((m) => Message.fromJson(m, _currentUserId ?? '')).toList();

      if (!mounted) return;

      setState(() {
        _messages = parsed;
        _original = parsed.isNotEmpty ? parsed.first : null;
      });

      if (scrollToBottom) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Kunne ikke hente tråd: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke hente beskedtråd: $e')),
        );
        Navigator.pop(context);
      }
    }
  }


  void _sendReply(String text) async {
    if (_original == null || _currentUserId == null) {
      print('❌ _original eller currentUserId er null');
      return;
    }

    final isMeSender = _original!.senderId == _currentUserId;
    final receiverId = isMeSender ? _original!.receiverId : _original!.senderId;

    if (receiverId.isEmpty) {
      print('❌ receiverId er tom');
      return;
    }

    final subject = _original!.subject.isNotEmpty
        ? 'Re: ${_original!.subject}'
        : 'Svar';

    print('📨 Klar til at sende: "$text"');
    print('➡️  Til: $receiverId');
    print('📎 ThreadId: ${_original!.threadId}');

    try {
      await MessageService.send(
        receiverId: receiverId,
        message: text,
        subject: subject,
        replyTo: _original!.threadId.toString(), // 👈 ikke message.id
      );

      _replyController.clear();
      await _loadMessages(scrollToBottom: true);
    } catch (e) {
      print('❌ Fejl ved send(): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke sende besked: $e')),
        );
      }
    }
  }




  Future<void> _deleteThread() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Slet samtale?',
        message: 'Er du sikker på, at du vil slette hele tråden?',
        onConfirm: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isDeleting = true);
      await MessageService.deleteThread(widget.threadId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tråden er slettet')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke slette tråd: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _formatDate(DateTime dt) {
    final today = DateTime.now();
    final messageDay = DateTime(dt.year, dt.month, dt.day);
    String dayPart;

    if (messageDay == DateTime(today.year, today.month, today.day)) {
      dayPart = 'I dag';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      dayPart = 'I går';
    } else {
      dayPart = DateFormat('dd.MM').format(dt);
    }

    final time = DateFormat('HH:mm').format(dt);
    return '$dayPart • $time';
  }

  @override
  Widget build(BuildContext context) {
    final subject = (_original?.subject != null && _original!.subject.isNotEmpty)
        ? _original!.subject
        : 'Uden emne';
    final sender = _original?.senderName ?? 'Ukendt afsender';
    final receiver = _original?.receiverName ?? 'Ukendt modtager';

    if (_original == null || _messages.isEmpty) {
      return const Scaffold(
        backgroundColor: generalBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: Text(
          subject,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _deleteThread,
            tooltip: 'Slet tråd',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fra: $sender',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Til: $receiver',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment:
                    msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      MessageBubble(
                        message: msg.message,
                        isMe: msg.isMe,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(msg.sentAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(color: generalBackground),
            child: ReplyInput(
              controller: _replyController,
              onSend: () {
                final text = _replyController.text.trim();
                if (text.isNotEmpty) _sendReply(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
