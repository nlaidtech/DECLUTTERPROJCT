import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/notification_model.dart';

/// Notification Service
/// Handles all notification operations - creating, fetching, marking as read, etc.
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  // ==================== FETCH NOTIFICATIONS ====================

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({int limit = 50}) async {
    if (currentUserId == null) return [];

    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    if (currentUserId == null) return 0;

    final response = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Get unread notifications only
  Future<List<NotificationModel>> getUnreadNotifications() async {
    if (currentUserId == null) return [];

    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', currentUserId!)
        .eq('is_read', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  // ==================== CREATE NOTIFICATIONS ====================

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedItemId,
    String? relatedUserId,
    String? relatedUserName,
    String? relatedUserAvatar,
    String? imageUrl,
  }) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'related_item_id': relatedItemId,
      'related_user_id': relatedUserId,
      'related_user_name': relatedUserName,
      'related_user_avatar': relatedUserAvatar,
      'image_url': imageUrl,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Create notification when someone saves a post
  Future<void> notifyPostSaved({
    required String postOwnerId,
    required String postId,
    required String postTitle,
    String? postImage,
  }) async {
    if (currentUserId == null || postOwnerId == currentUserId) return;

    final currentUser = await supabase
        .from('users')
        .select('name')
        .eq('id', currentUserId!)
        .single();

    await createNotification(
      userId: postOwnerId,
      type: 'post_saved',
      title: 'Post Saved',
      message: '${currentUser['name']} saved your post "$postTitle"',
      relatedItemId: postId,
      relatedUserId: currentUserId,
      relatedUserName: currentUser['name'],
      imageUrl: postImage,
    );
  }

  /// Create notification for new message
  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String messagePreview,
    String? senderAvatar,
  }) async {
    if (recipientId == senderId) return;

    await createNotification(
      userId: recipientId,
      type: 'message',
      title: 'New Message',
      message: '$senderName: $messagePreview',
      relatedUserId: senderId,
      relatedUserName: senderName,
      relatedUserAvatar: senderAvatar,
    );
  }

  // ==================== UPDATE NOTIFICATIONS ====================

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', currentUserId!)
        .eq('is_read', false);
  }

  // ==================== DELETE NOTIFICATIONS ====================

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await supabase.from('notifications').delete().eq('id', notificationId);
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;

    await supabase
        .from('notifications')
        .delete()
        .eq('user_id', currentUserId!);
  }

  // ==================== REALTIME SUBSCRIPTIONS ====================

  /// Subscribe to notification changes
  RealtimeChannel subscribeToNotifications(Function(NotificationModel) onNotification) {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    return supabase
        .channel('notifications:$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final notification = NotificationModel.fromJson(payload.newRecord);
            onNotification(notification);
          },
        )
        .subscribe();
  }
}
