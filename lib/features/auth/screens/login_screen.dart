import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../core/theme/aura_colors.dart';
import '../../../shared/widgets/aura_logo.dart';
import '../../../shared/widgets/landing_background.dart';
import '../../../shared/widgets/animated_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false; // Toggle between login and signup
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.vibrate();
      return;
    }

    FocusScope.of(context).unfocus();
    HapticUtils.mediumImpact();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await ref.read(authStateProvider.notifier).signUp(
              _emailController.text.trim(),
              _passwordController.text,
            );
      } else {
        await ref.read(authStateProvider.notifier).signIn(
              _emailController.text.trim(),
              _passwordController.text,
            );
      }
      
      // Success – go to dashboard (explicit nav so we don't rely only on redirect)
      HapticUtils.lightImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      HapticUtils.vibrate();
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      HapticUtils.vibrate();
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
    // Note: Don't set _isLoading = false in finally block for success case
    // The auth provider's loading state will be cleared by the auth state listener
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LandingBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 420,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AuraColors.darkSlateBg.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                const AuraLogo(size: 52, onLightBackground: false),
                                const SizedBox(height: 8),
                                Text(
                                  'Cloud-Based Smart Home AI Executive',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _isSignUp ? 'Create Account' : 'Welcome Back',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSignUp 
                                    ? 'Sign up to start controlling your smart home'
                                    : 'Sign in to control your smart home',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.white70,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(LucideIcons.mail),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AuraColors.teal,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AuraColors.coral,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(LucideIcons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? LucideIcons.eye
                                            : LucideIcons.eyeOff,
                                        color: Colors.white60,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AuraColors.teal,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AuraColors.coral,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _signIn(),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AuraColors.coral.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AuraColors.coral.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.alertCircle,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: AuraColors.coral,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                AnimatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  isLoading: _isLoading,
                                  icon: _isSignUp ? LucideIcons.userPlus : LucideIcons.logIn,
                                  backgroundColor: const Color(0xFF3B82F6),
                                  child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _isLoading ? null : () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                      _error = null;
                                    });
                                    HapticUtils.lightImpact();
                                  },
                                  child: Text(
                                    _isSignUp 
                                      ? 'Already have an account? Sign in'
                                      : 'Don\'t have an account? Sign up',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                                // Development bypass option
                                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                                  const SizedBox(height: 8),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _isLoading ? null : () async {
                                      HapticUtils.mediumImpact();
                                      // Create a test account automatically
                                      try {
                                        const testEmail = 'test@aura.local';
                                        const testPassword = 'test123456';
                                        setState(() {
                                          _isLoading = true;
                                          _error = null;
                                        });
                                        
                                        // Try to sign up with test credentials
                                        try {
                                          await ref.read(authStateProvider.notifier).signUp(
                                                testEmail,
                                                testPassword,
                                              );
                                        } catch (e) {
                                          // If sign up fails, try to sign in instead
                                          await ref.read(authStateProvider.notifier).signIn(
                                                testEmail,
                                                testPassword,
                                              );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          setState(() {
                                            _error = 'Failed to create test account. Please register manually.';
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    },
                                    child: const Text(
                                      '🚀 Quick Start (Create Test Account)',
                                      style: TextStyle(
                                        color: AuraColors.tealLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
