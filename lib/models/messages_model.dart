import 'package:intl/intl.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String subject;
  final String message;
  final DateTime sentAt;
  final String senderName;
  final String receiverName;
  final String senderType;
  final String threadId;
  final bool read;

  final bool isMe;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.subject,
    required this.message,
    required this.sentAt,
    required this.senderName,
    required this.receiverName,
    required this.senderType,
    required this.threadId,
    required this.read,
    required this.isMe,
  });

  factory Message.fromJson(Map<String, dynamic> json, String currentUserId) {
    return Message(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      sentAt: DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
          .parseUtc(json['sent_at']),
      senderName: json['sender_name'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      senderType: json['sender_type'] ?? '',
      threadId: json['thread_id'].toString(),
      read: json['read'] == 1,
      isMe: json['sender_id'].toString().trim() == currentUserId.trim(),
    );
  }
}
