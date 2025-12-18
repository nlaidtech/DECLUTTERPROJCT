import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Database Service
/// Handles all database operations for items, users, and messages
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ USERS ============
  
  /// Create user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    await _db.collection('users').doc(userId).set({
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'location': 'Panabo',
    });
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // ============ ITEMS ============
  
  /// Create a new item post
  Future<String> createItem({
    required String userId,
    required String title,
    required String description,
    required String category,
    required String location,
    List<String>? imageUrls,
  }) async {
    final docRef = await _db.collection('items').add({
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrls': imageUrls ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'available', // available, reserved, given
      'favorites': 0,
    });
    return docRef.id;
  }

  /// Get all available items
  Stream<QuerySnapshot> getAvailableItems() {
    return _db
        .collection('items')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get items by category
  Stream<QuerySnapshot> getItemsByCategory(String category) {
    return _db
        .collection('items')
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  /// Get user's posted items
  Stream<QuerySnapshot> getUserItems(String userId) {
    return _db
        .collection('items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update item status
  Future<void> updateItemStatus(String itemId, String status) async {
    await _db.collection('items').doc(itemId).update({'status': status});
  }

  /// Delete item
  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  // ============ FAVORITES ============
  
  /// Add item to favorites
  Future<void> addToFavorites(String userId, String itemId) async {
    await _db.collection('users').doc(userId).collection('favorites').doc(itemId).set({
      'itemId': itemId,
      'addedAt': FieldValue.serverTimestamp(),
    });
    
    // Increment favorite count
    await _db.collection('items').doc(itemId).update({
      'favorites': FieldValue.increment(1),
    });
  }

  /// Remove item from favorites
  Future<void> removeFromFavorites(String userId, String itemId) async {
    await _db.collection('users').doc(userId).collection('favorites').doc(itemId).delete();
    
    // Decrement favorite count
    await _db.collection('items').doc(itemId).update({
      'favorites': FieldValue.increment(-1),
    });
  }

  /// Get user's favorite items
  Stream<QuerySnapshot> getFavoriteItems(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Check if item is favorited
  Future<bool> isItemFavorited(String userId, String itemId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(itemId)
        .get();
    return doc.exists;
  }

  // ============ MESSAGES ============
  
  /// Create a new conversation
  Future<String> createConversation({
    required String user1Id,
    required String user2Id,
    String? itemId,
  }) async {
    final docRef = await _db.collection('conversations').add({
      'participants': [user1Id, user2Id],
      'itemId': itemId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    // Update conversation last message
    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Get messages in a conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Get user's conversations
  Stream<QuerySnapshot> getUserConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
