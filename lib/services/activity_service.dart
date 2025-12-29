import '../main.dart';
import '../models/activity_history_model.dart';

/// Activity History Service
/// Handles all activity tracking operations
class ActivityHistoryService {
  // Singleton pattern
  static final ActivityHistoryService _instance = ActivityHistoryService._internal();
  factory ActivityHistoryService() => _instance;
  ActivityHistoryService._internal();

  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  // ==================== FETCH ACTIVITY ====================

  /// Get all activity history for current user
  Future<List<ActivityHistoryModel>> getActivityHistory({
    int limit = 100,
    String? action,
  }) async {
    if (currentUserId == null) return [];

    var query = supabase
        .from('activity_history')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(limit);

    if (action != null) {
      final response = await supabase
          .from('activity_history')
          .select()
          .eq('user_id', currentUserId!)
          .eq('action', action)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => ActivityHistoryModel.fromJson(json))
          .toList();
    }

    final response = await query;

    return (response as List)
        .map((json) => ActivityHistoryModel.fromJson(json))
        .toList();
  }

  /// Get activity history grouped by date
  Future<Map<String, List<ActivityHistoryModel>>> getActivityByDate({
    int limit = 100,
  }) async {
    final activities = await getActivityHistory(limit: limit);
    final Map<String, List<ActivityHistoryModel>> grouped = {};

    for (var activity in activities) {
      final dateKey = _getDateKey(activity.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(activity);
    }

    return grouped;
  }

  /// Get activity statistics
  Future<Map<String, int>> getActivityStats() async {
    if (currentUserId == null) return {};

    final response = await supabase
        .from('activity_history')
        .select('action')
        .eq('user_id', currentUserId!);

    final stats = <String, int>{};
    for (var item in response as List) {
      final action = item['action'] as String;
      stats[action] = (stats[action] ?? 0) + 1;
    }

    return stats;
  }

  // ==================== CREATE ACTIVITY ====================

  /// Log a new activity
  Future<void> logActivity({
    required String action,
    required String title,
    required String description,
    String? relatedItemId,
    String? relatedItemTitle,
    String? relatedItemImage,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null) return;

    await supabase.from('activity_history').insert({
      'user_id': currentUserId,
      'action': action,
      'title': title,
      'description': description,
      'related_item_id': relatedItemId,
      'related_item_title': relatedItemTitle,
      'related_item_image': relatedItemImage,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Log post creation
  Future<void> logPostCreated({
    required String postId,
    required String postTitle,
    String? postImage,
  }) async {
    await logActivity(
      action: 'created_post',
      title: 'Created Post',
      description: 'You created a new post: $postTitle',
      relatedItemId: postId,
      relatedItemTitle: postTitle,
      relatedItemImage: postImage,
    );
  }

  /// Log post update
  Future<void> logPostUpdated({
    required String postId,
    required String postTitle,
    String? postImage,
  }) async {
    await logActivity(
      action: 'updated_post',
      title: 'Updated Post',
      description: 'You updated the post: $postTitle',
      relatedItemId: postId,
      relatedItemTitle: postTitle,
      relatedItemImage: postImage,
    );
  }

  /// Log post deletion
  Future<void> logPostDeleted({
    required String postTitle,
  }) async {
    await logActivity(
      action: 'deleted_post',
      title: 'Deleted Post',
      description: 'You deleted the post: $postTitle',
      relatedItemTitle: postTitle,
    );
  }

  /// Log post saved
  Future<void> logPostSaved({
    required String postId,
    required String postTitle,
    String? postImage,
  }) async {
    await logActivity(
      action: 'saved_post',
      title: 'Saved Post',
      description: 'You saved the post: $postTitle',
      relatedItemId: postId,
      relatedItemTitle: postTitle,
      relatedItemImage: postImage,
    );
  }

  /// Log post unsaved
  Future<void> logPostUnsaved({
    required String postId,
    required String postTitle,
  }) async {
    await logActivity(
      action: 'unsaved_post',
      title: 'Unsaved Post',
      description: 'You removed the post from saved: $postTitle',
      relatedItemId: postId,
      relatedItemTitle: postTitle,
    );
  }

  /// Log message sent
  Future<void> logMessageSent({
    required String recipientName,
    String? messagePreview,
  }) async {
    await logActivity(
      action: 'sent_message',
      title: 'Sent Message',
      description: 'You sent a message to $recipientName',
      metadata: {'preview': messagePreview},
    );
  }

  /// Log profile update
  Future<void> logProfileUpdated() async {
    await logActivity(
      action: 'profile_updated',
      title: 'Profile Updated',
      description: 'You updated your profile information',
    );
  }

  // ==================== DELETE ACTIVITY ====================

  /// Delete an activity
  Future<void> deleteActivity(String activityId) async {
    await supabase.from('activity_history').delete().eq('id', activityId);
  }

  /// Delete all activity history for current user
  Future<void> deleteAllActivity() async {
    if (currentUserId == null) return;

    await supabase
        .from('activity_history')
        .delete()
        .eq('user_id', currentUserId!);
  }

  /// Delete old activity (older than specified days)
  Future<void> deleteOldActivity({int daysToKeep = 90}) async {
    if (currentUserId == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await supabase
        .from('activity_history')
        .delete()
        .eq('user_id', currentUserId!)
        .lt('created_at', cutoffDate.toIso8601String());
  }

  // ==================== HELPER METHODS ====================

  /// Get date key for grouping (e.g., "Today", "Yesterday", "Jan 15, 2024")
  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) {
      return 'Today';
    } else if (activityDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
