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

  /// Delete account and all associated data
  Future<void> deleteAccount() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw 'No user logged in';
    }

    try {
      // Delete user profile and related data (CASCADE will handle posts, messages, etc.)
      await supabase.from('users').delete().eq('id', userId);
      
      // Delete the auth user (requires admin privileges or RPC function)
      // Note: This requires a database function to be set up in Supabase
      await supabase.rpc('delete_user');
      
      // Sign out
      await signOut();
    } on PostgrestException catch (e) {
      throw 'Error deleting account: ${e.message}';
    } catch (e) {
      throw 'Failed to delete account: ${e.toString()}';
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    // Don't refresh session here if it was already refreshed by caller
    // to avoid double refresh which can cause issues
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      print('Error fetching profile: ${e.message}');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    // Refresh session to ensure user is authenticated
    await supabase.auth.refreshSession();
    
    try {
      // First check if profile exists
      final existing = await getUserProfile(userId);
      
      if (existing == null) {
        // Create new profile if it doesn't exist
        await supabase.from('profiles').insert({
          'id': userId,
          'email': currentUser?.email ?? '',
          ...updates,
        });
      } else {
        // Update existing profile
        await supabase.from('profiles').update(updates).eq('id', userId);
      }
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
