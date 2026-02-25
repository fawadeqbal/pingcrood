import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/theme_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.sendMessage(_messageController.text.trim());
      _messageController.clear();
      _stopTyping();
      _scrollToBottom();
    }
  }

  void _onTextChanged(String value) {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    if (value.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chat.sendTypingEvent(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () => _stopTyping());
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      Provider.of<ChatProvider>(context, listen: false).sendTypingEvent(false);
    }
    _typingTimer?.cancel();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _stopTyping();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  String _formatMessageTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today ${DateFormat('HH:mm').format(dt)}';
    }
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.id;
    final t = Provider.of<ThemeProvider>(context);

    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        String otherName = 'Chat';
        bool isOtherOnline = false;
        bool isOtherTyping = false;

        if (chat.activeRoomId != null) {
          final activeRoom = chat.rooms.where((r) => r.id == chat.activeRoomId).toList();
          if (activeRoom.isNotEmpty) {
            final room = activeRoom.first;
            final otherMembers = room.members.where((m) => m.userId != currentUserId).toList();
            if (otherMembers.isNotEmpty) {
              final other = otherMembers.first;
              otherName = other.user.username ?? other.user.email ?? 'Unknown';
              isOtherOnline = chat.onlineUserIds.contains(other.userId);
            }
            isOtherTyping = chat.isTyping(room.id);
          }
        }

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 32,
            title: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [t.accentAvatarStart, t.accentAvatarEnd]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(otherName[0].toUpperCase(), style: TextStyle(color: t.accent, fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (isOtherOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: t.online,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.bgPrimary, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary)),
                      const SizedBox(height: 2),
                      if (isOtherTyping)
                        Text('typing...', style: TextStyle(fontSize: 11, color: t.accent, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500))
                      else
                        Text(
                          isOtherOnline ? 'Online' : 'Offline',
                          style: TextStyle(fontSize: 11, color: isOtherOnline ? t.online : t.textMuted, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.phone_rounded, color: t.textMuted, size: 20),
                onPressed: () {
                  if (chat.activeRoomId != null) {
                    Provider.of<CallProvider>(context, listen: false)
                        .initiateCall(chat.activeRoomId!, 'AUDIO');
                  }
                },
                tooltip: 'Audio Call',
              ),
              IconButton(
                icon: Icon(Icons.videocam_rounded, color: t.textMuted, size: 22),
                onPressed: () {
                  if (chat.activeRoomId != null) {
                    Provider.of<CallProvider>(context, listen: false)
                        .initiateCall(chat.activeRoomId!, 'VIDEO');
                  }
                },
                tooltip: 'Video Call',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final messages = chat.currentRoomMessages;
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waving_hand_rounded, size: 48, color: t.textDim),
                            const SizedBox(height: 16),
                            Text('Say hello! 👋', style: TextStyle(fontSize: 16, color: t.textMuted)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUserId;
                        // In reverse list, next older message is at index+1
                        final showTime = index == messages.length - 1 ||
                            messages[index].createdAt.difference(messages[index + 1].createdAt).inMinutes.abs() > 5;

                        return Column(
                          children: [
                            if (showTime)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  _formatMessageTime(message.createdAt),
                                  style: TextStyle(fontSize: 10, color: t.textDim, fontWeight: FontWeight.w500),
                                ),
                              ),
                            Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                decoration: BoxDecoration(
                                  gradient: isMe ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]) : null,
                                  color: isMe ? null : t.msgOtherBg,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(message.content, style: TextStyle(color: isMe ? t.msgMeText : t.msgOtherText, fontSize: 14, height: 1.4)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('HH:mm').format(message.createdAt), style: TextStyle(fontSize: 10, color: isMe ? t.msgMeTime : t.msgOtherTime)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Typing indicator
              if (isOtherTyping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: t.msgOtherBg, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.4, end: 1.0),
                              duration: Duration(milliseconds: 600 + i * 200),
                              builder: (context, val, _) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: t.accent.withOpacity(val), shape: BoxShape.circle),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$otherName is typing', style: TextStyle(fontSize: 11, color: t.textMuted, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),

              // Message Input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: t.bgPrimary,
                  border: Border(top: BorderSide(color: t.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: t.bgInput, borderRadius: BorderRadius.circular(24)),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: t.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: t.textDim),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onChanged: _onTextChanged,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: t.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
