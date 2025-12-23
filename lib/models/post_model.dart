import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Create PostModel from Firestore document
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      type: data['type'] ?? 'available',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      viewCount: data['viewCount'] ?? 0,
      isFavorite: data['isFavorite'] ?? false,
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert PostModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'type': type,
      'imageUrls': imageUrls,
      'rating': rating,
      'viewCount': viewCount,
      'isFavorite': isFavorite,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
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
