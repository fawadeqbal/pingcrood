import 'user_model.dart';
import 'message_model.dart';

class RoomModel {
  final String id;
  final String type; // PRIVATE, GROUP
  final List<RoomMember> members;
  final MessageModel? lastMessage;
  final int unreadCount;

  RoomModel({
    required this.id,
    required this.type,
    required this.members,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? (json['isGroup'] == true ? 'GROUP' : 'PRIVATE'),
      members: json['members'] != null
          ? (json['members'] as List).map((m) => RoomMember.fromJson(m)).toList()
          : [],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class RoomMember {
  final String userId;
  final UserModel user;

  RoomMember({required this.userId, required this.user});

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      userId: json['userId']?.toString() ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
