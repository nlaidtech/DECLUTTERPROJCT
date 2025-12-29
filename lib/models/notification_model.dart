// Notification Model - Represents notification data structure
class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'like', 'message', 'comment', 'follow', 'post_saved'
  final String title;
  final String message;
  final String? relatedItemId; // Post ID, message ID, etc.
  final String? relatedUserId; // User who triggered the notification
  final String? relatedUserName;
  final String? relatedUserAvatar;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedItemId,
    this.relatedUserId,
    this.relatedUserName,
    this.relatedUserAvatar,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  // Create from Supabase JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedItemId: json['related_item_id'] as String?,
      relatedUserId: json['related_user_id'] as String?,
      relatedUserName: json['related_user_name'] as String?,
      relatedUserAvatar: json['related_user_avatar'] as String?,
      imageUrl: json['image_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'related_item_id': relatedItemId,
      'related_user_id': relatedUserId,
      'related_user_name': relatedUserName,
      'related_user_avatar': relatedUserAvatar,
      'image_url': imageUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? relatedItemId,
    String? relatedUserId,
    String? relatedUserName,
    String? relatedUserAvatar,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedUserName: relatedUserName ?? this.relatedUserName,
      relatedUserAvatar: relatedUserAvatar ?? this.relatedUserAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get icon for notification type
  String get icon {
    switch (type) {
      case 'like':
        return '❤️';
      case 'message':
        return '💬';
      case 'comment':
        return '💭';
      case 'follow':
        return '👤';
      case 'post_saved':
        return '🔖';
      default:
        return '🔔';
    }
  }
}
