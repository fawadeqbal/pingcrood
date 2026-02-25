import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!success && mounted) {
      final t = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login failed. Please check your credentials.'),
          backgroundColor: t.snackbarError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.bgGradientStart, t.bgGradientMid, t.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Theme toggle
              Positioned(
                top: 8,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    t.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: t.textSecondary,
                    size: 22,
                  ),
                  onPressed: () => t.toggleTheme(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: t.accent.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 32),
                        Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text('Sign in to continue chatting', style: TextStyle(fontSize: 14, color: t.textSecondary)),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: t.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined, color: t.iconMuted, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: t.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, color: t.iconMuted, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: t.iconMuted, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleLogin,
                                child: auth.isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: t.textSecondary, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: Text('Sign Up', style: TextStyle(color: t.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
