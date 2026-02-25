import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ─── Color Tokens ───

  // Backgrounds
  Color get bgPrimary => _isDarkMode ? const Color(0xFF0A0A1A) : const Color(0xFFF8F9FC);
  Color get bgSurface => _isDarkMode ? const Color(0xFF111128) : Colors.white;
  Color get bgInput => _isDarkMode ? const Color(0xFF1A1A3E) : const Color(0xFFF0F1F5);
  Color get bgCard => _isDarkMode ? const Color(0xFF111128) : Colors.white;
  Color get bgGradientStart => _isDarkMode ? const Color(0xFF0A0A1A) : const Color(0xFFF8F9FC);
  Color get bgGradientMid => _isDarkMode ? const Color(0xFF15153A) : const Color(0xFFF0F1F8);
  Color get bgGradientEnd => _isDarkMode ? const Color(0xFF0D0D2B) : const Color(0xFFE8E9F0);

  // Text
  Color get textPrimary => _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
  Color get textSecondary => _isDarkMode ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280);
  Color get textMuted => _isDarkMode ? Colors.white.withOpacity(0.35) : const Color(0xFF9CA3AF);
  Color get textDim => _isDarkMode ? Colors.white.withOpacity(0.25) : const Color(0xFFBCC0C8);
  Color get textOnPrimary => Colors.white;

  // Accent
  Color get accent => const Color(0xFF7C3AED);
  Color get accentLight => _isDarkMode ? const Color(0xFF7C3AED).withOpacity(0.15) : const Color(0xFFEDE9FE);
  Color get accentAvatarStart => _isDarkMode ? const Color(0xFF7C3AED).withOpacity(0.3) : const Color(0xFFEDE9FE);
  Color get accentAvatarEnd => _isDarkMode ? const Color(0xFF6366F1).withOpacity(0.3) : const Color(0xFFE0E7FF);

  // Borders
  Color get border => _isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE5E7EB);
  Color get borderInput => _isDarkMode ? const Color(0xFF7C3AED) : const Color(0xFF7C3AED);

  // Message Bubbles
  Color get msgMeBg => const Color(0xFF7C3AED);
  Color get msgOtherBg => _isDarkMode ? const Color(0xFF1A1A3E) : const Color(0xFFF0F1F5);
  Color get msgMeText => Colors.white;
  Color get msgOtherText => _isDarkMode ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E);
  Color get msgMeTime => Colors.white.withOpacity(0.6);
  Color get msgOtherTime => _isDarkMode ? Colors.white.withOpacity(0.25) : const Color(0xFF9CA3AF);

  // Status
  Color get online => const Color(0xFF22C55E);
  Color get onlineBorder => _isDarkMode ? const Color(0xFF111128) : Colors.white;

  // Icons & misc
  Color get iconMuted => _isDarkMode ? Colors.white.withOpacity(0.4) : const Color(0xFF9CA3AF);
  Color get snackbarError => Colors.red.shade700;

  ThemeData get themeData {
    return ThemeData(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: _isDarkMode
          ? const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              secondary: Color(0xFF6366F1),
              surface: Color(0xFF111128),
            )
          : const ColorScheme.light(
              primary: Color(0xFF7C3AED),
              secondary: Color(0xFF6366F1),
              surface: Colors.white,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderInput, width: 1.5),
        ),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textDim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
