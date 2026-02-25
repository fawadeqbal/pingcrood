import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../chat/chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();

  void _onSearchChanged(String value) {
    Provider.of<ChatProvider>(context, listen: false).searchUsers(value);
  }

  void _startChat(String userId) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final roomId = await chat.startPrivateChat(userId);
    if (roomId != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32,
        title: Container(
          height: 44,
          decoration: BoxDecoration(color: t.bgInput, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: t.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by username...',
              hintStyle: TextStyle(color: t.textDim),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.search_rounded, color: t.iconMuted, size: 20),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.isLoading) {
            return Center(child: CircularProgressIndicator(color: t.accent, strokeWidth: 2));
          }

          if (_searchController.text.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: t.accentLight, borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.search_rounded, size: 36, color: t.accent.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text('Find friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Search by username to start chatting', style: TextStyle(fontSize: 13, color: t.textMuted)),
                ],
              ),
            );
          }

          if (chat.searchResults.isEmpty) {
            return Center(child: Text('No users found', style: TextStyle(fontSize: 14, color: t.textMuted)));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chat.searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final user = chat.searchResults[index];
              final displayName = user.username ?? user.email ?? 'Unknown';

              return Container(
                decoration: BoxDecoration(
                  color: t.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.accentAvatarStart, t.accentAvatarEnd]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(displayName[0].toUpperCase(), style: TextStyle(color: t.accent, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  title: Text(displayName, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(user.email ?? '', style: TextStyle(fontSize: 12, color: t.textMuted)),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _startChat(user.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: t.accentLight, borderRadius: BorderRadius.circular(12)),
                      child: Text('Chat', style: TextStyle(color: t.accent, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
