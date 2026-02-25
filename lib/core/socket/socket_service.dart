import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_client.dart';

class SocketService {
  IO.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineListController = StreamController<List<String>>.broadcast();

  // Call event stream controllers
  final _callIncomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callDeclinedController = StreamController<void>.broadcast();
  final _callEndedController = StreamController<void>.broadcast();
  final _callSignalController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;
  Stream<List<String>> get onlineListStream => _onlineListController.stream;

  // Call event streams
  Stream<Map<String, dynamic>> get callIncomingStream => _callIncomingController.stream;
  Stream<Map<String, dynamic>> get callAcceptedStream => _callAcceptedController.stream;
  Stream<void> get callDeclinedStream => _callDeclinedController.stream;
  Stream<void> get callEndedStream => _callEndedController.stream;
  Stream<Map<String, dynamic>> get callSignalStream => _callSignalController.stream;

  void connect(String token) {
    final s = IO.io(ApiClient.baseUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build()
    );
    _socket = s;

    s.onConnect((_) {
      print('Socket connected');
    });

    // Chat events
    s.on('message:new', (data) => _messageController.add(Map<String, dynamic>.from(data)));
    s.on('typing', (data) => _typingController.add(Map<String, dynamic>.from(data)));
    s.on('user:online', (data) => _presenceController.add({...Map<String, dynamic>.from(data), 'status': 'ONLINE'}));
    s.on('user:offline', (data) => _presenceController.add({...Map<String, dynamic>.from(data), 'status': 'OFFLINE'}));

    s.on('user:online_list', (data) {
      if (data is Map && data.containsKey('onlineIds')) {
        _onlineListController.add(List<String>.from(data['onlineIds']));
      } else if (data is List) {
        _onlineListController.add(List<String>.from(data));
      }
    });

    // Call events
    s.on('call:incoming', (data) => _callIncomingController.add(Map<String, dynamic>.from(data)));
    s.on('call:accepted', (data) => _callAcceptedController.add(Map<String, dynamic>.from(data)));
    s.on('call:declined', (_) => _callDeclinedController.add(null));
    s.on('call:ended', (_) => _callEndedController.add(null));
    s.on('call:signal', (data) => _callSignalController.add(Map<String, dynamic>.from(data)));

    s.onDisconnect((_) => print('Socket disconnected'));
  }

  // Chat emitters
  void joinRoom(String roomId) {
    _socket?.emit('room:join', roomId);
  }

  void leaveRoom(String roomId) {
    _socket?.emit('room:leave', roomId);
  }

  void sendMessage(String roomId, String content, {String? clientId}) {
    _socket?.emit('message:send', {
      'roomId': roomId,
      'content': content,
      'clientId': clientId,
    });
  }

  void sendTyping(String roomId, bool isTyping) {
    _socket?.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void markAsSeen(String roomId) {
    _socket?.emit('message:seen', {'roomId': roomId});
  }

  // Call emitters
  void callInit(String roomId, String type) {
    _socket?.emit('call:init', {'roomId': roomId, 'type': type});
  }

  void callAnswer(String callId, String roomId, bool accepted) {
    _socket?.emit('call:answer', {
      'callId': callId,
      'roomId': roomId,
      'accepted': accepted,
    });
  }

  void callSignal(String roomId, dynamic signal, {String? toUserId}) {
    _socket?.emit('call:signal', {
      'roomId': roomId,
      'signal': signal,
      if (toUserId != null) 'toUserId': toUserId,
    });
  }

  void callHangup(String callId, String roomId) {
    _socket?.emit('call:hangup', {'callId': callId, 'roomId': roomId});
  }

  void dispose() {
    _messageController.close();
    _typingController.close();
    _presenceController.close();
    _onlineListController.close();
    _callIncomingController.close();
    _callAcceptedController.close();
    _callDeclinedController.close();
    _callEndedController.close();
    _callSignalController.close();
    _socket?.disconnect();
  }
}
