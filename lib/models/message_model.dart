enum MessageStatus { SENT, DELIVERED, SEEN }

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String type; // TEXT, IMAGE, FILE
  final List<dynamic>? attachments;
  final DateTime createdAt;
  final MessageStatus status;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.type = 'TEXT',
    this.attachments,
    required this.createdAt,
    this.status = MessageStatus.SENT,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      content: json['content'],
      type: json['type'] ?? 'TEXT',
      attachments: json['attachments'],
      createdAt: DateTime.parse(json['createdAt']),
      status: _parseStatus(json['status']),
    );
  }

  static MessageStatus _parseStatus(String? status) {
    switch (status) {
      case 'DELIVERED':
        return MessageStatus.DELIVERED;
      case 'SEEN':
        return MessageStatus.SEEN;
      default:
        return MessageStatus.SENT;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }
}
