import 'dart:io';

class Message {
  final String id;
  final String threadId;
  final String subject;
  final String message;
  final DateTime sentAt;
  final bool isMe;
  final String senderName;
  final String receiverName;

  final String senderId;
  final String receiverId;

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

  factory Message.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderId = json['sender_id'].toString();
    final receiverId = json['receiver_id'].toString();

    return Message(
      id: json['id'].toString(),
      threadId: json['thread_id'].toString(),
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      sentAt: HttpDate.parse(json['sent_at']),
      isMe: senderId == currentUserId,
      senderName: json['sender_name'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      senderId: senderId,
      receiverId: receiverId,
    );
  }
}
