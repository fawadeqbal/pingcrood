import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/socket/socket_service.dart';

class CallProvider extends ChangeNotifier {
  final SocketService _socketService;

  // State
  Map<String, dynamic>? _incomingCall;
  Map<String, dynamic>? _activeCall;
  bool _isCalling = false;
  bool _isMicOn = true;
  bool _isVideoOn = true;
  int _callDuration = 0;
  Timer? _durationTimer;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  String? _otherUserId;
  String? _roomId;
  bool _initialized = false;

  // Getters
  Map<String, dynamic>? get incomingCall => _incomingCall;
  Map<String, dynamic>? get activeCall => _activeCall;
  bool get isCalling => _isCalling;
  bool get isMicOn => _isMicOn;
  bool get isVideoOn => _isVideoOn;
  int get callDuration => _callDuration;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get hasActiveCallUI => _incomingCall != null || _activeCall != null || _isCalling;

  String get formattedDuration {
    final mins = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final secs = (_callDuration % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  CallProvider(this._socketService);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _listenToEvents();
  }

  void _listenToEvents() {
    _socketService.callIncomingStream.listen((data) {
      _incomingCall = data;
      notifyListeners();
    });

    _socketService.callAcceptedStream.listen((data) async {
      _activeCall = data;
      _isCalling = false;
      _otherUserId = data['userId']?.toString();
      _roomId = data['roomId']?.toString();
      notifyListeners();

      // Caller: create offer after acceptance
      if (_localStream != null) {
        if (_peerConnection != null) {
          await _peerConnection!.close();
          _peerConnection = null;
        }
        await _createPeerConnection(_localStream!);
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        _socketService.callSignal(
          _roomId!,
          offer.toMap(),
          toUserId: _otherUserId,
        );
      }
    });

    _socketService.callDeclinedStream.listen((_) {
      _cleanupCall();
      notifyListeners();
    });

    _socketService.callEndedStream.listen((_) {
      _cleanupCall();
      notifyListeners();
    });

    _socketService.callSignalStream.listen((data) async {
      final fromUserId = data['fromUserId']?.toString() ?? '';
      final signal = data['signal'];

      if (signal == null) return;

      try {
        if (signal is Map) {
          if (signal['type'] == 'offer') {
            _otherUserId = fromUserId;
            if (_peerConnection == null && _localStream != null) {
              await _createPeerConnection(_localStream!);
            }
            if (_peerConnection != null) {
              await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(signal['sdp'], signal['type']),
              );
              final answer = await _peerConnection!.createAnswer();
              await _peerConnection!.setLocalDescription(answer);
              _socketService.callSignal(
                _roomId!,
                answer.toMap(),
                toUserId: fromUserId,
              );
            }
          } else if (signal['type'] == 'answer') {
            if (_peerConnection != null) {
              await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(signal['sdp'], signal['type']),
              );
            }
          } else if (signal['candidate'] != null) {
            if (_peerConnection != null) {
              await _peerConnection!.addCandidate(
                RTCIceCandidate(
                  signal['candidate'],
                  signal['sdpMid'],
                  signal['sdpMLineIndex'],
                ),
              );
            }
          }
        }
      } catch (e) {
        print('Error handling call signal: $e');
      }
    });
  }

  Future<void> _createPeerConnection(MediaStream stream) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    // Add local tracks
    for (final track in stream.getTracks()) {
      await _peerConnection!.addTrack(track, stream);
    }

    // Handle remote stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        notifyListeners();
      }
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_roomId != null && _otherUserId != null) {
        _socketService.callSignal(
          _roomId!,
          candidate.toMap(),
          toUserId: _otherUserId,
        );
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      print('ICE Connection State: $state');
    };
  }

  // --- Public Actions ---

  Future<void> initiateCall(String roomId, String type) async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': type == 'VIDEO',
      });
      localRenderer.srcObject = _localStream;
      _isMicOn = true;
      _isVideoOn = type == 'VIDEO';
      _isCalling = true;
      _roomId = roomId;
      notifyListeners();

      _socketService.callInit(roomId, type);
    } catch (e) {
      print('Failed to get media devices: $e');
    }
  }

  Future<void> answerCall(bool accepted) async {
    if (_incomingCall == null) return;

    if (accepted) {
      try {
        final callType = _incomingCall!['type']?.toString() ?? 'AUDIO';
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': callType == 'VIDEO',
        });
        localRenderer.srcObject = _localStream;
        _isMicOn = true;
        _isVideoOn = callType == 'VIDEO';
        _activeCall = _incomingCall;
        _roomId = _incomingCall!['roomId']?.toString();
        _otherUserId = _incomingCall!['fromUserId']?.toString();

        _socketService.callAnswer(
          _incomingCall!['callId']?.toString() ?? '',
          _incomingCall!['roomId']?.toString() ?? '',
          true,
        );

        _startDurationTimer();
        _incomingCall = null;
        notifyListeners();
      } catch (e) {
        print('Failed to answer call: $e');
        _socketService.callAnswer(
          _incomingCall!['callId']?.toString() ?? '',
          _incomingCall!['roomId']?.toString() ?? '',
          false,
        );
        _incomingCall = null;
        notifyListeners();
      }
    } else {
      _socketService.callAnswer(
        _incomingCall!['callId']?.toString() ?? '',
        _incomingCall!['roomId']?.toString() ?? '',
        false,
      );
      _incomingCall = null;
      notifyListeners();
    }
  }

  void hangupCall() {
    final call = _activeCall ?? _incomingCall;
    if (call != null) {
      _socketService.callHangup(
        (call['callId'] ?? call['id'] ?? '').toString(),
        (call['roomId'] ?? '').toString(),
      );
    }
    _cleanupCall();
    notifyListeners();
  }

  void toggleMic() {
    _isMicOn = !_isMicOn;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = _isMicOn;
    });
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOn = !_isVideoOn;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = _isVideoOn;
    });
    notifyListeners();
  }

  void _startDurationTimer() {
    _callDuration = 0;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      notifyListeners();
    });
  }

  void _cleanupCall() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callDuration = 0;

    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    localRenderer.srcObject = null;

    _remoteStream?.dispose();
    _remoteStream = null;
    remoteRenderer.srcObject = null;

    _activeCall = null;
    _incomingCall = null;
    _isCalling = false;
    _isMicOn = true;
    _isVideoOn = true;
    _otherUserId = null;
    _roomId = null;
  }

  @override
  void dispose() {
    _cleanupCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}
