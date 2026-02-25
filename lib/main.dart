import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/call_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/call/call_screen.dart';
import 'core/socket/socket_service.dart';

void main() {
  // Shared socket instance used by both ChatProvider and CallProvider
  final socketService = SocketService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(socketService),
          update: (_, auth, chat) {
            if (auth.isAuthenticated && auth.user != null) {
              chat!.init(auth.token!, auth.user!.id);
            }
            return chat!;
          },
        ),
        ChangeNotifierProvider(create: (_) => CallProvider(socketService)),
      ],
      child: const ChatApp(),
    ),
  );
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'NextByte Chat',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData.copyWith(
            textTheme: GoogleFonts.interTextTheme(
              themeProvider.isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
            ),
          ),
          builder: (context, child) {
            // CallOverlay wraps the entire app so it's always visible
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const CallOverlay(),
              ],
            );
          },
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                // Initialize CallProvider when authenticated
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<CallProvider>(context, listen: false).init();
                });
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
