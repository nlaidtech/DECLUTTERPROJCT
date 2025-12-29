import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

/// Supabase Authentication Service
/// Handles user sign up, login, logout, and password reset
class AuthService {
  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account with Supabase Auth
      // The trigger will automatically create the user profile
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Store name in user metadata
      );

      // Log response for debugging
      print('Signup response: ${response.user?.id}, session: ${response.session != null}');

      return response;
    } on AuthException catch (e) {
      print('AuthException: ${e.message}, code: ${e.statusCode}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Supabase
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } on PostgrestException catch (e) {
      throw 'Error fetching profile: ${e.message}';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await supabase.from('profiles').update(updates).eq('id', userId);
    } on PostgrestException catch (e) {
      throw 'Error updating profile: ${e.message}';
    }
  }

  /// Handle Supabase Auth exceptions
  String _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('user already registered')) {
      return 'This email is already registered. Please login instead.';
    } else if (message.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('email not confirmed')) {
      return 'Please verify your email address';
    } else if (message.contains('password')) {
      return 'Password must be at least 6 characters';
    } else if (message.contains('invalid email')) {
      return 'Invalid email address';
    } else if (message.contains('too many requests')) {
      return 'Too many attempts. Please try again later';
    } else {
      return 'Authentication error: ${e.message}';
    }
  }
}
