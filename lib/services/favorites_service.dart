import 'package:flutter/material.dart';
import 'activity_service.dart';

/// FavoritesService
///
/// Manages the list of favorited/saved items globally.
/// 
/// HOW IT WORKS:
/// - Uses ChangeNotifier pattern from Flutter
/// - When favorites change, notifyListeners() alerts all widgets listening
/// - Widgets rebuild automatically to show updated favorites
/// 
/// SINGLETON PATTERN:
/// - Only ONE instance exists in the entire app
/// - Accessible anywhere: FavoritesService().addFavorite(...)
/// - No need to pass it through constructors
/// 
/// CURRENT IMPLEMENTATION:
/// - Stores favorites in memory (lost when app closes)
/// - Uses item titles as IDs
/// 
/// FUTURE IMPROVEMENT:
/// - Save to Supabase database for persistence across devices
/// - Use actual post IDs instead of titles
/// - Sync favorites across user's devices
///
/// USAGE EXAMPLE:
/// ```dart
/// // Add to favorites
/// FavoritesService().addFavorite('Sofa', postId: '123', imageUrl: 'url');
/// 
/// // Check if favorited
/// bool saved = FavoritesService().isFavorite('Sofa');
/// 
/// // Listen to changes in widget
/// ListenableBuilder(
///   listenable: FavoritesService(),
///   builder: (context, child) {
///     // Rebuilds when favorites change
///     return Text('${FavoritesService().favorites.length} saved');
///   }
/// )
/// ```

class FavoritesService with ChangeNotifier {
  // Singleton instance - only one exists in entire app
  static final FavoritesService _instance = FavoritesService._internal();

  // Private constructor - prevents creating new instances
  FavoritesService._internal();

  // Factory constructor - always returns the same instance
  factory FavoritesService() {
    return _instance;
  }

  // Store favorites as a Set (no duplicates allowed)
  // Currently uses titles, should use IDs in production
  final Set<String> _favorites = {};

  // Getter to expose favorites as a list
  // Returns a copy to prevent external modification
  List<String> get favorites => _favorites.toList();

  /// Check if an item is favorited
  /// 
  /// Parameters:
  /// - itemTitle: The title of the item to check
  /// 
  /// Returns: true if item is in favorites, false otherwise
  bool isFavorite(String itemTitle) => _favorites.contains(itemTitle);

  /// Add an item to favorites
  /// 
  /// Flow:
  /// 1. Check if item already favorited (avoid duplicates)
  /// 2. Add to favorites set
  /// 3. Call notifyListeners() to update UI everywhere
  /// 4. Log activity for user's history
  /// 
  /// Parameters:
  /// - itemTitle: Title of the item
  /// - postId: (Optional) Post ID for activity logging
  /// - imageUrl: (Optional) Image URL for activity display
  void addFavorite(String itemTitle, {String? postId, String? imageUrl}) {
    if (!_favorites.contains(itemTitle)) {
      _favorites.add(itemTitle);
      notifyListeners(); // Alert all listening widgets to rebuild
      
      // Log this action in activity history
      if (postId != null) {
        ActivityHistoryService().logPostSaved(
          postId: postId,
          postTitle: itemTitle,
          postImage: imageUrl,
        );
      }
    }
  }

  /// Remove an item from favorites
  /// 
  /// Flow:
  /// 1. Check if item is favorited
  /// 2. Remove from favorites set
  /// 3. Call notifyListeners() to update UI
  /// 4. Log activity for user's history
  void removeFavorite(String itemTitle, {String? postId}) {
    if (_favorites.contains(itemTitle)) {
      _favorites.remove(itemTitle);
      notifyListeners(); // Alert all listening widgets
      
      // Log this action in activity history
      if (postId != null) {
        ActivityHistoryService().logPostUnsaved(
          postId: postId,
          postTitle: itemTitle,
        );
      }
    }
  }

  /// Toggle an item's favorite status
  /// 
  /// Convenience method that calls either add or remove
  /// Used for favorite button toggles in UI
  void toggleFavorite(String itemTitle, {String? postId, String? imageUrl}) {
    if (isFavorite(itemTitle)) {
      removeFavorite(itemTitle, postId: postId);
    } else {
      addFavorite(itemTitle, postId: postId, imageUrl: imageUrl);
    }
  }

  /// Clear all favorites
  /// 
  /// Useful for:
  /// - Logout (clear user's data)
  /// - Testing
  /// - Bulk operations
  void clearAll() {
    _favorites.clear();
    notifyListeners(); // Update UI everywhere
  }
}
