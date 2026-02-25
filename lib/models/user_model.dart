class UserModel {
  final String id;
  final String? email;
  final String? username;
  final String? avatarUrl;
  final String presence; // ONLINE, OFFLINE
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    this.email,
    this.username,
    this.avatarUrl,
    this.presence = 'OFFLINE',
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      presence: json['presence'] ?? 'OFFLINE',
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'presence': presence,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}
