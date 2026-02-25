import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
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
    _usernameController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _usernameController.text.trim(),
    );
    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      final t = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration failed. Please try again.'),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: t.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
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
                              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 44),
                          ),
                          const SizedBox(height: 32),
                          Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Text('Join the conversation today', style: TextStyle(fontSize: 14, color: t.textSecondary)),
                          const SizedBox(height: 48),
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: t.textPrimary),
                            decoration: InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline, color: t.iconMuted, size: 20)),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: t.textPrimary),
                            decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: t.iconMuted, size: 20)),
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
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return ElevatedButton(
                                  onPressed: auth.isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
