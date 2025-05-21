import 'dart:io';

class Message {
  final int id;
  final String senderName;
  final String receiverName;
  final String message;
  final DateTime sentAt;
  final bool isMe;
  final String subject;

  Message({
    required this.id,
    required this.senderName,
    required this.receiverName,
    required this.message,
    required this.sentAt,
    required this.isMe,
    required this.subject,
  });

  factory Message.fromJson(Map<String, dynamic> json, int currentUserId) {
    return Message(
      id: json['id'],
      senderName: json['sender_name'],
      receiverName: json['receiver_name'],
      message: json['message'],
      sentAt: HttpDate.parse(json['sent_at']),
      isMe: json['sender_id'] == currentUserId,
      subject: json['subject'] ?? '', // 👈
    );
  }
}
