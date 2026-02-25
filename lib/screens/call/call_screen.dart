import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../providers/call_provider.dart';
import '../../providers/theme_provider.dart';

class CallOverlay extends StatelessWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        if (call.incomingCall != null) {
          return _IncomingCallDialog(call: call);
        }
        if (call.activeCall != null || call.isCalling) {
          return _ActiveCallView(call: call);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ──────────────────────────────────────────
// Incoming Call Dialog
// ──────────────────────────────────────────
class _IncomingCallDialog extends StatelessWidget {
  final CallProvider call;
  const _IncomingCallDialog({required this.call});

  @override
  Widget build(BuildContext context) {
    final incoming = call.incomingCall!;
    final callerName = incoming['fromUserName']?.toString() ?? 'Unknown';
    final callType = incoming['type']?.toString() ?? 'AUDIO';
    final isVideo = callType == 'VIDEO';

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing icon
              Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 1000),
                    builder: (_, value, __) => Container(
                      width: 96 * value,
                      height: 96 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                      ),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                      ),
                      boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 24)],
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${callType.toLowerCase()} Call',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'from $callerName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C3AED),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decline
                  GestureDetector(
                    onTap: () => call.answerCall(false),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.red, size: 28),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Accept
                  GestureDetector(
                    onTap: () => call.answerCall(true),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 16)],
                      ),
                      child: const Icon(Icons.phone_rounded, color: Colors.green, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Active Call View
// ──────────────────────────────────────────
class _ActiveCallView extends StatelessWidget {
  final CallProvider call;
  const _ActiveCallView({required this.call});

  @override
  Widget build(BuildContext context) {
    final callData = call.activeCall;
    final userName = callData?['userName']?.toString() ?? '';
    final isCalling = call.isCalling;

    return Material(
      color: const Color(0xFF0A0A1A),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCalling ? 'CALLING...' : 'ON CALL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      if (!isCalling && userName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      call.formattedDuration,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Video area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111128),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Stack(
                  children: [
                    // Remote video (full)
                    if (call.remoteStream != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: RTCVideoView(
                          call.remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: Icon(
                                Icons.videocam_rounded,
                                size: 28,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isCalling ? 'Ringing...' : 'Waiting for peer...',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.3),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Local video (PiP)
                    if (call.localStream != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RTCVideoView(
                              call.localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic toggle
                  _ControlButton(
                    icon: call.isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    isActive: !call.isMicOn,
                    onTap: call.toggleMic,
                  ),
                  // Video toggle
                  _ControlButton(
                    icon: call.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    isActive: !call.isVideoOn,
                    onTap: call.toggleVideo,
                  ),
                  // Hangup
                  GestureDetector(
                    onTap: call.hangupCall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 16)],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'HANG UP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.red : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}
