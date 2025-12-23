import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore Database Service
/// Handles all database operations for posts, messages, and user data
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER PROFILE ====================

  /// Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? location,
  }) async {
    await _db.collection('users').doc(userId).set({
      'email': email,
      'displayName': displayName ?? email.split('@')[0],
      'photoUrl': photoUrl,
      'location': location ?? 'PANABO',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
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
      print('ERROR: User not logged in!');
      throw Exception('User not logged in');
    }

    print('Creating post for user: $currentUserId');

    final postData = {
      'userId': currentUserId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'type': type,
      'imageUrls': imageUrls ?? [],
      'rating': 0.0,
      'viewCount': 0,
      'isFavorite': false,
      'status': 'active', // active, reserved, completed
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    print('Post data: $postData');

    final docRef = await _db.collection('posts').add(postData);

    print('Post added with ID: ${docRef.id}');

    return docRef.id;
  }

  /// Get all posts (with optional filters)
  Stream<QuerySnapshot> getPosts({
    String? type, // 'giveaway' or 'available'
    String? category,
    String? status,
  }) {
    Query query = _db.collection('posts');

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // Only order by createdAt if no filters are applied
    // (to avoid requiring Firestore index)
    if (type == null && category == null && status == null) {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots();
  }

  /// Get user's posts
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  /// Update post
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('posts').doc(postId).update(data);
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // ==================== FAVORITES ====================

  /// Toggle favorite status
  Future<void> toggleFavorite(String postId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final favRef = _db
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(postId);

    final doc = await favRef.get();

    if (doc.exists) {
      // Remove from favorites
      await favRef.delete();
    } else {
      // Add to favorites
      await favRef.set({
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get user's favorite posts
  Stream<QuerySnapshot> getFavoritePosts() {
    if (currentUserId == null) {
      return Stream.value(
        FirebaseFirestore.instance.collection('posts').limit(0).get()
            as QuerySnapshot,
      );
    }

    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .snapshots();
  }

  /// Check if post is favorited
  Future<bool> isFavorite(String postId) async {
    if (currentUserId == null) return false;

    final doc = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(postId)
        .get();

    return doc.exists;
  }

  // ==================== MESSAGES / CHATS ====================

  /// Create or get existing chat between two users
  Future<String> getOrCreateChat(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    // Create a consistent chat ID (sorted user IDs)
    final users = [currentUserId!, otherUserId]..sort();
    final chatId = '${users[0]}_${users[1]}';

    final chatRef = _db.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'users': users,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');

    // Add message to messages subcollection
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    // Update last message in chat document
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Get messages in a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Get user's conversations
  Stream<QuerySnapshot> getConversations() {
    if (currentUserId == null) {
      return Stream.value(
        FirebaseFirestore.instance.collection('chats').limit(0).get()
            as QuerySnapshot,
      );
    }

    return _db
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // ==================== NOTIFICATIONS ====================

  /// Create a notification
  Future<void> createNotification({
    required String recipientId,
    required String type, // 'message', 'interest', 'review'
    required String title,
    required String body,
    String? postId,
    String? chatId,
  }) async {
    await _db.collection('notifications').add({
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'body': body,
      'postId': postId,
      'chatId': chatId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user's notifications
  Stream<QuerySnapshot> getNotifications() {
    if (currentUserId == null) {
      return Stream.value(
        FirebaseFirestore.instance.collection('notifications').limit(0).get()
            as QuerySnapshot,
      );
    }

    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }
}
