import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = ChangeNotifierProvider<AuthStateNotifier>((ref) {
  final notifier = AuthStateNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Authentication state notifier with proper error handling and state management.
class AuthStateNotifier extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;

  User? get value => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthStateNotifier() {
    _init();
  }

  void _init() {
    try {
      _user = Supabase.instance.client.auth.currentUser;
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;
          
          debugPrint('🔐 Auth state changed: ${event.name}');
          
          // Only update if the user actually changed to prevent unnecessary rebuilds
          final newUser = session?.user;
          if (_user?.id != newUser?.id) {
            _user = newUser;
            _error = null;
            // Clear loading state when auth state changes (sign-in/sign-out complete)
            _isLoading = false;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('❌ Auth state listener error: $error');
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to initialize auth state: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sign in with email and password
  /// 
  /// Throws [AuthException] if authentication fails
  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password cannot be empty');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Sign in failed: No user returned');
      }
      
      // Update user immediately so router redirect sees auth before navigation
      _user = response.user;
      _error = null;
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Successfully signed in: ${response.user?.email ?? 'Unknown'}');
      
      await Future.delayed(const Duration(milliseconds: 100));
    } on AuthException catch (e) {
      _error = e.message;
      debugPrint('❌ Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Unexpected error during sign in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  /// 
  /// Throws [AuthException] if registration fails
  Future<void> signUp(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password cannot be empty');
    }

    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Sign up failed: No user returned');
      }
      
      _user = response.user;
      _error = null;
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Successfully signed up: ${response.user?.email ?? 'Unknown'}');
      
      await Future.delayed(const Duration(milliseconds: 100));
    } on AuthException catch (e) {
      _error = e.message;
      debugPrint('❌ Auth error during sign up: ${e.message}');
      rethrow;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Unexpected error during sign up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
      _user = null;
      _error = null;
      debugPrint('✅ Successfully signed out');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error during sign out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cancel auth state subscription when provider is disposed.
  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}
