import 'package:flutter/material.dart';
import 'activity_service.dart';

/// FavoritesService
///
/// Manages the list of favorited items globally. Uses a ChangeNotifier so that
/// screens and widgets can listen for changes and rebuild when favorites are
/// added or removed.
///
/// Implemented as a singleton so it's accessible anywhere in the app without
/// needing to pass it through constructors.
///
/// In a real app, you'd persist this to local storage (shared_preferences) or
/// a backend database. For now, it lives in memory during the app session.

class FavoritesService with ChangeNotifier {
  // Singleton instance
  static final FavoritesService _instance = FavoritesService._internal();

  // Private constructor
  FavoritesService._internal();

  // Factory constructor to return the singleton
  factory FavoritesService() {
    return _instance;
  }

  // Store favorites as a Set of item titles (or IDs in a real app).
  final Set<String> _favorites = {};

  // Getter to expose the favorites as an unmodifiable list
  List<String> get favorites => _favorites.toList();

  // Check if an item is favorited
  bool isFavorite(String itemTitle) => _favorites.contains(itemTitle);

  // Add an item to favorites
  void addFavorite(String itemTitle, {String? postId, String? imageUrl}) {
    if (!_favorites.contains(itemTitle)) {
      _favorites.add(itemTitle);
      notifyListeners(); // Notify all listeners (widgets) of the change
      
      // Log activity
      if (postId != null) {
        ActivityHistoryService().logPostSaved(
          postId: postId,
          postTitle: itemTitle,
          postImage: imageUrl,
        );
      }
    }
  }

  // Remove an item from favorites
  void removeFavorite(String itemTitle, {String? postId}) {
    if (_favorites.contains(itemTitle)) {
      _favorites.remove(itemTitle);
      notifyListeners();
      
      // Log activity
      if (postId != null) {
        ActivityHistoryService().logPostUnsaved(
          postId: postId,
          postTitle: itemTitle,
        );
      }
    }
  }

  // Toggle an item's favorite status
  void toggleFavorite(String itemTitle, {String? postId, String? imageUrl}) {
    if (isFavorite(itemTitle)) {
      removeFavorite(itemTitle, postId: postId);
    } else {
      addFavorite(itemTitle, postId: postId, imageUrl: imageUrl);
    }
  }

  // Clear all favorites
  void clearAll() {
    _favorites.clear();
    notifyListeners();
  }
}
