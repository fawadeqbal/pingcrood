import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/socket/socket_service.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SocketService _socketService;
  
  List<RoomModel> _rooms = [];
  Map<String, List<MessageModel>> _messagesByRoom = {};
  List<UserModel>? _searchResults;
  String? _activeRoomId;
  String? _currentUserId;
  bool _isLoading = false;
  
  Set<String> _onlineUserIds = {};
  Set<String> _typingRoomIds = {};
  final Set<String> _seenMessageIds = {};
  bool _initialized = false;

  ChatProvider(this._socketService);

  List<RoomModel> get rooms => _rooms;
  List<MessageModel> get currentRoomMessages => _messagesByRoom[_activeRoomId] ?? [];
  List<UserModel> get searchResults => _searchResults ?? [];
  bool get isLoading => _isLoading;
  String? get activeRoomId => _activeRoomId;
  Set<String> get onlineUserIds => _onlineUserIds;
  bool isTyping(String roomId) => _typingRoomIds.contains(roomId);

  void init(String token, String userId) {
    if (_initialized) return; // Prevent duplicate socket connections
    _initialized = true;
    _currentUserId = userId;
    _socketService.connect(token);
    _listenToEvents();
    fetchRooms();
  }

  void _listenToEvents() {
    _socketService.messageStream.listen((data) {
      final message = MessageModel.fromJson(data);
      
      // Fast Set-based deduplication — backend emits message:new twice
      // (once to room channel, once to user: personal channel)
      if (_seenMessageIds.contains(message.id)) return;
      _seenMessageIds.add(message.id);
      
      // Insert at beginning to maintain descending order (newest first)
      if (_messagesByRoom.containsKey(message.roomId)) {
        _messagesByRoom[message.roomId]!.insert(0, message);
      } else {
        _messagesByRoom[message.roomId] = [message];
      }
      
      // Move room to top of list
      final roomIndex = _rooms.indexWhere((r) => r.id == message.roomId);
      if (roomIndex > 0) {
        final room = _rooms.removeAt(roomIndex);
        _rooms.insert(0, room);
      }
      notifyListeners();
    });

    _socketService.presenceStream.listen((data) {
      final String userId = data['userId']?.toString() ?? '';
      final String status = data['status']?.toString() ?? 'OFFLINE';
      
      if (status == 'ONLINE') {
        _onlineUserIds.add(userId);
      } else {
        _onlineUserIds.remove(userId);
      }
      notifyListeners();
    });

    _socketService.onlineListStream.listen((ids) {
      _onlineUserIds = Set<String>.from(ids);
      notifyListeners();
    });

    _socketService.typingStream.listen((data) {
      final String roomId = data['roomId']?.toString() ?? '';
      final bool isTyping = data['isTyping'] == true;
      
      if (isTyping) {
        _typingRoomIds.add(roomId);
      } else {
        _typingRoomIds.remove(roomId);
      }
      notifyListeners();
    });
  }

  Future<void> fetchRooms() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.getRooms();
      _rooms = (response.data as List).map((r) => RoomModel.fromJson(r)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveRoom(String roomId) async {
    _activeRoomId = roomId;
    _socketService.joinRoom(roomId);
    if (!_messagesByRoom.containsKey(roomId)) {
      await fetchMessages(roomId);
    }
    notifyListeners();
  }

  Future<void> fetchMessages(String roomId) async {
    try {
      final response = await _apiClient.getMessages(roomId);
      // Keep in descending order (newest first) — ListView with reverse:true handles display
      final messages = (response.data as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
      _messagesByRoom[roomId] = messages;
      notifyListeners();
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.searchUsers(query);
      
      if (response.data != null) {
        final List<dynamic> data = response.data as List;
        final List<UserModel> allUsers = data.map((u) {
          final map = u as Map<String, dynamic>;
          return UserModel(
            id: map['id']?.toString() ?? '',
            email: map['email']?.toString(),
            username: map['username']?.toString(),
            avatarUrl: map['avatarUrl']?.toString(),
            presence: map['presence']?.toString() ?? 'OFFLINE',
          );
        }).toList();
        
        _searchResults = allUsers.where((u) => u.id != (_currentUserId ?? '')).toList();
      } else {
        _searchResults = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Search error: $e');
      _searchResults = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> startPrivateChat(String targetUserId) async {
    try {
      final response = await _apiClient.createPrivateRoom(targetUserId);
      final room = RoomModel.fromJson(response.data);
      if (!_rooms.any((r) => r.id == room.id)) {
        _rooms.insert(0, room);
      }
      await setActiveRoom(room.id);
      return room.id;
    } catch (e) {
      print('Error starting chat: $e');
      return null;
    }
  }

  void sendTypingEvent(bool typing) {
    if (_activeRoomId != null) {
      _socketService.sendTyping(_activeRoomId!, typing);
    }
  }

  void markRoomAsSeen() {
    if (_activeRoomId != null) {
      _socketService.markAsSeen(_activeRoomId!);
    }
  }

  void sendMessage(String content) {
    if (_activeRoomId != null) {
      _socketService.sendMessage(_activeRoomId!, content);
    }
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
