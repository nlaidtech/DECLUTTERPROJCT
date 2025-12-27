/// Post Model
/// Represents a post (item) that users create to give away or make available
class PostModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String type; // 'giveaway' or 'available'
  final List<String> imageUrls;
  final double rating;
  final int viewCount;
  final bool isFavorite;
  final String status; // 'active', 'reserved', 'completed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.type,
    this.imageUrls = const [],
    this.rating = 0.0,
    this.viewCount = 0,
    this.isFavorite = false,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  /// Create PostModel from Supabase JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? 'available',
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls'])
          : [],
      rating: (json['rating'] ?? 0.0).toDouble(),
      viewCount: json['view_count'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert PostModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'type': type,
      'image_urls': imageUrls,
      'rating': rating,
      'view_count': viewCount,
      'status': status,
    };
  }

  /// Create a copy of PostModel with updated fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? location,
    String? type,
    List<String>? imageUrls,
    double? rating,
    int? viewCount,
    bool? isFavorite,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      rating: rating ?? this.rating,
      viewCount: viewCount ?? this.viewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
