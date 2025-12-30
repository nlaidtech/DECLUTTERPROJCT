import 'package:timeago/timeago.dart' as timeago;

/// Chat Message Model - Enhanced Version
/// 
/// Represents a single chat message with full metadata:
/// - Unique identifier for each message
/// - Message content (text/image)
/// - Sender information (name, avatar)
/// - Timestamps (sent, delivered, read)
/// - Message status tracking
/// - Reply/thread support
class ChatMessage {
  // Core message data
  final String id; // Unique message identifier
  final String text; // Message content
  final DateTime timestamp; // When message was sent
  final bool isSentByMe; // true = sent by current user, false = received
  
  // Sender information
  final String senderName; // Name of the person who sent the message
  final String? senderAvatar; // URL or path to sender's avatar image
  
  // Message status (for sent messages)
  final MessageStatus status; // sent, delivered, read
  
  // Optional features
  final String? imageUrl; // URL for image messages
  final String? replyToId; // ID of message being replied to
  final MessageType type; // text, image, system
  
  ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    required this.senderName,
    this.senderAvatar,
    this.status = MessageStatus.sent,
    this.imageUrl,
    this.replyToId,
    this.type = MessageType.text,
  });

  /// Creates a copy of this message with some fields replaced
  ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isSentByMe,
    String? senderName,
    String? senderAvatar,
    MessageStatus? status,
    String? imageUrl,
    String? replyToId,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      replyToId: replyToId ?? this.replyToId,
      type: type ?? this.type,
    );
  }

  /// Formats timestamp to readable time (e.g., "10:30 AM")
  /// Converts UTC to Philippines local time (UTC+8)
  String get formattedTime {
    final localTime = timestamp.toLocal(); // Convert UTC to local timezone
    final hour = localTime.hour > 12 ? localTime.hour - 12 : localTime.hour;
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
  
  /// Formats timestamp to relative time (e.g., "2 hours ago", "23 minutes ago")
  /// Updates automatically in real-time
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Formats timestamp to date (e.g., "Dec 15, 2025")
  String get formattedDate {
    final localTime = timestamp.toLocal(); // Convert UTC to local timezone
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[localTime.month - 1]} ${localTime.day}, ${localTime.year}';
  }

  /// Checks if this message is from today
  bool get isToday {
    final now = DateTime.now();
    final localTime = timestamp.toLocal(); // Convert UTC to local timezone
    return localTime.year == now.year &&
           localTime.month == now.month &&
           localTime.day == now.day;
  }

  /// Converts message to JSON format (useful for storage/API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isSentByMe': isSentByMe,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'status': status.name,
      'imageUrl': imageUrl,
      'replyToId': replyToId,
      'type': type.name,
    };
  }

  /// Creates a message from JSON format
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSentByMe: json['isSentByMe'] as bool,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: json['imageUrl'] as String?,
      replyToId: json['replyToId'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  @override
  String toString() => 'ChatMessage(id: $id, text: $text, isSentByMe: $isSentByMe, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Message status for tracking delivery
enum MessageStatus {
  sent,      // Message sent from device
  delivered, // Message delivered to recipient's device
  read,      // Message read by recipient
}

/// Type of message content
enum MessageType {
  text,   // Regular text message
  image,  // Image message
  system, // System notification (e.g., "User joined")
}
