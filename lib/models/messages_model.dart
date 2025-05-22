import 'dart:io';

class Message {
  final int id;
  final int threadId;
  final String subject;
  final String message;
  final DateTime sentAt;
  final bool isMe;
  final String senderName;
  final String receiverName;

  final int senderId;
  final int receiverId;

  Message({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.message,
    required this.sentAt,
    required this.isMe,
    required this.senderName,
    required this.receiverName,
    required this.senderId,
    required this.receiverId,
  });

  factory Message.fromJson(Map<String, dynamic> json, int currentUserId) {
    return Message(
      id: json['id'],
      threadId: json['thread_id'],
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      sentAt: HttpDate.parse(json['sent_at']),
      isMe: json['sender_id'] == currentUserId,
      senderName: json['sender_name'] ?? '',
      receiverName: json['receiver_name'] ?? '',

      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
    );
  }
}
