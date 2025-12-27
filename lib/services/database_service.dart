import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

/// Supabase Database Service
/// Handles all database operations for posts, messages, and user data
class DatabaseService {
  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  // ==================== USER PROFILE ====================

  /// Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? location,
  }) async {
    await supabase.from('users').upsert({
      'id': userId,
      'email': email,
      'name': displayName ?? email.split('@')[0],
      // Add location field if needed in your users table
    });
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  // ==================== POSTS (Items) ====================

  /// Create a new post (giveaway/available item)
  Future<String> createPost({
    required String title,
    required String description,
    required String category,
    required String location,
    required String type, // 'giveaway' or 'available'
    List<String>? imageUrls,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase.from('posts').insert({
      'user_id': currentUserId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'type': type,
      'image_urls': imageUrls ?? [],
      'status': 'active',
    }).select('id').single();

    return response['id'] as String;
  }

  /// Get all posts (with optional filters)
  Stream<List<Map<String, dynamic>>> getPosts({
    String? type,
    String? category,
    String? status,
  }) {
    var query = supabase.from('posts').stream(primaryKey: ['id']);

    // Note: Supabase Realtime doesn't support .eq() chaining on streams
    // For filtered data, use regular queries instead
    return query;
  }

  /// Get all posts as a one-time query (with filters)
  Future<List<Map<String, dynamic>>> getPostsOnce({
    String? type,
    String? category,
    String? status,
  }) async {
    var query = supabase.from('posts').select();

    if (type != null) {
      query = query.eq('type', type);
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final result = await query.order('created_at', ascending: false);

    return result as List<Map<String, dynamic>>;
  }

  /// Get user's posts
  Stream<List<Map<String, dynamic>>> getUserPosts(String userId) {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }

  /// Update post
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await supabase.from('posts').update(data).eq('id', postId);
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    await supabase.from('posts').delete().eq('id', postId);
  }

  /// Increment view count
  Future<void> incrementViewCount(String postId) async {
    await supabase.rpc('increment_view_count', params: {'post_id': postId});
  }

  // ==================== FAVORITES ====================

  /// Toggle favorite status
  Future<void> toggleFavorite(String postId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final existing = await supabase
        .from('favorites')
        .select()
        .eq('user_id', currentUserId!)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      // Remove from favorites
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('post_id', postId);
    } else {
      // Add to favorites
      await supabase.from('favorites').insert({
        'user_id': currentUserId,
        'post_id': postId,
      });
    }
  }

  /// Get user's favorite posts
  Stream<List<Map<String, dynamic>>> getFavoritePosts() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return supabase
        .from('favorites')
        .stream(primaryKey: ['user_id', 'post_id'])
        .eq('user_id', currentUserId!);
  }

  /// Get favorite posts with post details
  Future<List<Map<String, dynamic>>> getFavoritePostsWithDetails() async {
    if (currentUserId == null) return [];

    final response = await supabase
        .from('favorites')
        .select('*, posts(*)')
        .eq('user_id', currentUserId!);

    return response as List<Map<String, dynamic>>;
  }

  /// Check if post is favorited
  Future<bool> isFavorite(String postId) async {
    if (currentUserId == null) return false;

    final response = await supabase
        .from('favorites')
        .select()
        .eq('user_id', currentUserId!)
        .eq('post_id', postId)
        .maybeSingle();

    return response != null;
  }

  // ==================== MESSAGES / CHATS ====================

  /// Create or get existing conversation
  Future<String> getOrCreateChat(String otherUserId, {String? postId}) async {
    if (currentUserId == null) throw Exception('User not logged in');

    // Check if conversation already exists between these users
    final existing = await supabase
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', currentUserId!)
        .select();

    // For now, create a new conversation
    final convResponse = await supabase.from('conversations').insert({
      'post_id': postId,
    }).select('id').single();

    final conversationId = convResponse['id'] as String;

    // Add participants
    await supabase.from('conversation_participants').insert([
      {'conversation_id': conversationId, 'user_id': currentUserId},
      {'conversation_id': conversationId, 'user_id': otherUserId},
    ]);

    return conversationId;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? imageUrl,
    String? replyToId,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');

    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'text': text,
      'image_url': imageUrl,
      'reply_to_id': replyToId,
      'message_type': imageUrl != null ? 'image' : 'text',
    });

    // Update conversation's updated_at
    await supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  /// Get messages in a conversation
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  /// Get user's conversations with latest message
  Future<List<Map<String, dynamic>>> getConversations() async {
    if (currentUserId == null) return [];

    // Get conversations where user is a participant
    final response = await supabase
        .from('conversation_participants')
        .select('conversation_id, conversations(*)')
        .eq('user_id', currentUserId!)
        .order('conversations.updated_at', ascending: false);

    return response as List<Map<String, dynamic>>;
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    await supabase
        .from('messages')
        .update({'status': 'read'})
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId!);
  }
}
