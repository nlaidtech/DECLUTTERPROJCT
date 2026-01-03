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
    // Insert into users table (basic info only)
    await supabase.from('users').upsert({
      'id': userId,
      'email': email,
      'name': displayName ?? email.split('@')[0],
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
  /// 
  /// This function:
  /// 1. Validates the user is logged in
  /// 2. Ensures the user exists in the users table (creates if missing)
  /// 3. Inserts the post into the database
  /// 4. Returns the post ID
  /// 
  /// Parameters:
  /// - title: The title of the post
  /// - description: Detailed description of the item
  /// - category: Category of the item (e.g., "Giveaway")
  /// - location: Location where the item is available
  /// - type: Either 'giveaway' or 'available'
  /// - imageUrls: List of image URLs uploaded to storage
  /// - latitude/longitude: GPS coordinates of the item location
  Future<String> createPost({
    required String title,
    required String description,
    required String category,
    required String location,
    required String type, // 'giveaway' or 'available'
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) async {
    // Step 1: Refresh the authentication session to ensure user is still logged in
    await supabase.auth.refreshSession();
    
    // Step 2: Check if user is authenticated
    if (currentUserId == null) {
      print('ERROR: User not logged in when creating post');
      print('Current session: ${supabase.auth.currentSession}');
      throw Exception('User not logged in');
    }

    // Step 3: Verify user exists in users table (required for foreign key constraint)
    // The posts table has a foreign key to users.id, so user must exist first
    final userExists = await supabase
        .from('users')
        .select('id')
        .eq('id', currentUserId!)
        .maybeSingle();
    
    // Step 4: If user doesn't exist in users table, create them
    // This can happen if the user was created in auth but not in users table
    if (userExists == null) {
      final user = supabase.auth.currentUser;
      await saveUserProfile(
        userId: currentUserId!,
        email: user?.email ?? '',
        displayName: user?.userMetadata?['name'] ?? user?.email?.split('@')[0],
      );
      print('Created missing user record for: $currentUserId');
    }

    // Step 5: Insert the post into the database
    // The .select('id').single() returns the inserted post's ID
    final response = await supabase.from('posts').insert({
      'user_id': currentUserId,  // Links post to the user who created it
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'type': type,  // 'giveaway' or 'available'
      'image_urls': imageUrls ?? [],  // Array of image URLs from Firebase Storage
      'latitude': latitude,  // GPS coordinates for map view
      'longitude': longitude,
      'status': 'active',  // Can be: active, reserved, completed
    }).select('id').single();

    // Step 6: Return the newly created post ID
    return response['id'] as String;
  }

  /// Get all posts (with optional filters)
  Stream<List<Map<String, dynamic>>> getPosts({
    String? type,
    String? category,
    String? status,
  }) {
    // Build query with profile join
    var query = supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return query.asyncMap((posts) async {
      var filtered = posts;
      
      // Apply filters
      if (type != null) {
        filtered = filtered.where((post) => post['type'] == type).toList();
      }
      if (category != null) {
        filtered = filtered.where((post) => post['category'] == category).toList();
      }
      if (status != null) {
        filtered = filtered.where((post) => post['status'] == status).toList();
      }
      
      // Fetch profiles for each post
      final postsWithProfiles = await Future.wait(
        filtered.map((post) async {
          final userId = post['user_id'];
          if (userId != null) {
            final profile = await supabase
                .from('profiles')
                .select('id, email, display_name, photo_url, created_at')
                .eq('id', userId)
                .maybeSingle();
            post['profiles'] = profile;
          }
          return post;
        }),
      );
      
      return postsWithProfiles;
    });
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

    final posts = await query.order('created_at', ascending: false);
    
    // Fetch user profiles for each post
    final postsWithProfiles = await Future.wait(
      posts.map((post) async {
        final userId = post['user_id'];
        if (userId != null) {
          final profile = await supabase
              .from('profiles')
              .select('id, email, display_name, photo_url, created_at')
              .eq('id', userId)
              .maybeSingle();
          post['profiles'] = profile;
        }
        return post;
      }).toList(),
    );
    
    return List<Map<String, dynamic>>.from(postsWithProfiles);
  }

  /// Search posts by title or description
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Search in title and description, only active posts
    final posts = await supabase
        .from('posts')
        .select()
        .eq('status', 'active')
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false);
    
    // Fetch user profiles for each post
    final postsWithProfiles = await Future.wait(
      posts.map((post) async {
        final userId = post['user_id'];
        if (userId != null) {
          final profile = await supabase
              .from('profiles')
              .select('id, email, display_name, photo_url, created_at')
              .eq('id', userId)
              .maybeSingle();
          post['profiles'] = profile;
        }
        return post;
      }).toList(),
    );
    
    return List<Map<String, dynamic>>.from(postsWithProfiles);
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

    return List<Map<String, dynamic>>.from(response);
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
    // (Note: This is simplified - in production you'd check for existing conversations)

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

    return List<Map<String, dynamic>>.from(response);
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
