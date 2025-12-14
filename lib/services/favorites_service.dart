import 'package:flutter/material.dart';

/// FavoritesService
///
/// Manages the list of favorited items globally. Uses a ChangeNotifier so that
/// screens and widgets can listen for changes and rebuild when favorites are
/// added or removed.
///
/// In a real app, you'd persist this to local storage (shared_preferences) or
/// a backend database. For now, it lives in memory during the app session.

class FavoritesService with ChangeNotifier {
  // Store favorites as a Set of item titles (or IDs in a real app).
  final Set<String> _favorites = {};

  // Getter to expose the favorites as an unmodifiable list
  List<String> get favorites => _favorites.toList();

  // Check if an item is favorited
  bool isFavorite(String itemTitle) => _favorites.contains(itemTitle);

  // Add an item to favorites
  void addFavorite(String itemTitle) {
    if (!_favorites.contains(itemTitle)) {
      _favorites.add(itemTitle);
      notifyListeners(); // Notify all listeners (widgets) of the change
    }
  }

  // Remove an item from favorites
  void removeFavorite(String itemTitle) {
    if (_favorites.contains(itemTitle)) {
      _favorites.remove(itemTitle);
      notifyListeners();
    }
  }

  // Toggle an item's favorite status
  void toggleFavorite(String itemTitle) {
    if (isFavorite(itemTitle)) {
      removeFavorite(itemTitle);
    } else {
      addFavorite(itemTitle);
    }
  }

  // Clear all favorites
  void clearAll() {
    _favorites.clear();
    notifyListeners();
  }
}
