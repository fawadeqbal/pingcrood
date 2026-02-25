import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../chat/chat_screen.dart';
import 'user_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.textPrimary)),
            Consumer<ChatProvider>(
              builder: (context, chat, _) {
                final count = chat.onlineUserIds.length;
                return Text(
                  '$count contact${count != 1 ? 's' : ''} online',
                  style: TextStyle(fontSize: 11, color: t.online, fontWeight: FontWeight.w500),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              t.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: t.textSecondary,
              size: 20,
            ),
            onPressed: () => t.toggleTheme(),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.textPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_rounded, size: 20, color: t.textSecondary),
            ),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.isLoading && chat.rooms.isEmpty) {
            return Center(child: CircularProgressIndicator(color: t.accent, strokeWidth: 2));
          }

          if (chat.rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: t.accentLight, borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.chat_bubble_outline_rounded, size: 36, color: t.accent.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Tap + to start a new chat', style: TextStyle(fontSize: 13, color: t.textMuted)),
                ],
              ),
            );
          }

          final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: chat.rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final room = chat.rooms[index];
              final otherMembers = room.members.where((m) => m.userId != currentUserId).toList();
              if (otherMembers.isEmpty) return const SizedBox.shrink();
              final other = otherMembers.first;

              final isOnline = chat.onlineUserIds.contains(other.userId);
              final isRoomTyping = chat.isTyping(room.id);
              final displayName = other.user.username ?? other.user.email ?? 'Unknown';

              return Container(
                decoration: BoxDecoration(
                  color: t.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [t.accentAvatarStart, t.accentAvatarEnd]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(displayName[0].toUpperCase(), style: TextStyle(color: t.accent, fontSize: 20, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: t.online,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.onlineBorder, width: 2.5),
                              boxShadow: [BoxShadow(color: t.online.withOpacity(0.5), blurRadius: 6)],
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: t.textPrimary)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: isRoomTyping
                        ? Text('typing...', style: TextStyle(color: t.accent, fontStyle: FontStyle.italic, fontSize: 12, fontWeight: FontWeight.w500))
                        : Text(
                            room.lastMessage?.content ?? 'Start a conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: t.textMuted),
                          ),
                  ),
                  onTap: () {
                    chat.setActiveRoom(room.id);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSearchScreen())),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
