// Activity History Model - Represents user activity data
class ActivityHistoryModel {
  final String id;
  final String userId;
  final String action; // 'created_post', 'updated_post', 'deleted_post', 'saved_post', 'unsaved_post', 'sent_message', 'profile_updated'
  final String title;
  final String description;
  final String? relatedItemId; // Post ID, message ID, etc.
  final String? relatedItemTitle;
  final String? relatedItemImage;
  final Map<String, dynamic>? metadata; // Additional data specific to action type
  final DateTime createdAt;

  ActivityHistoryModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.title,
    required this.description,
    this.relatedItemId,
    this.relatedItemTitle,
    this.relatedItemImage,
    this.metadata,
    required this.createdAt,
  });

  // Create from Supabase JSON
  factory ActivityHistoryModel.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      relatedItemId: json['related_item_id'] as String?,
      relatedItemTitle: json['related_item_title'] as String?,
      relatedItemImage: json['related_item_image'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'title': title,
      'description': description,
      'related_item_id': relatedItemId,
      'related_item_title': relatedItemTitle,
      'related_item_image': relatedItemImage,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method
  ActivityHistoryModel copyWith({
    String? id,
    String? userId,
    String? action,
    String? title,
    String? description,
    String? relatedItemId,
    String? relatedItemTitle,
    String? relatedItemImage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ActivityHistoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      title: title ?? this.title,
      description: description ?? this.description,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      relatedItemTitle: relatedItemTitle ?? this.relatedItemTitle,
      relatedItemImage: relatedItemImage ?? this.relatedItemImage,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get icon for activity type
  String get icon {
    switch (action) {
      case 'created_post':
        return '✨';
      case 'updated_post':
        return '✏️';
      case 'deleted_post':
        return '🗑️';
      case 'saved_post':
        return '🔖';
      case 'unsaved_post':
        return '📌';
      case 'sent_message':
        return '💬';
      case 'profile_updated':
        return '👤';
      default:
        return '📝';
    }
  }

  // Get color for activity type
  String get colorHex {
    switch (action) {
      case 'created_post':
        return '#4CAF50'; // green
      case 'updated_post':
        return '#2196F3'; // blue
      case 'deleted_post':
        return '#F44336'; // red
      case 'saved_post':
        return '#FF9800'; // orange
      case 'unsaved_post':
        return '#9E9E9E'; // grey
      case 'sent_message':
        return '#9C27B0'; // purple
      case 'profile_updated':
        return '#00BCD4'; // cyan
      default:
        return '#607D8B'; // blue grey
    }
  }
}
