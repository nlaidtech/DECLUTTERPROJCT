import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

/// SavedScreen
///
/// This screen displays all items the user has marked as favorites (by clicking
/// the heart icon). Items are shown as a list. If no items are favorited, a
/// friendly empty message is displayed.
///
/// The screen rebuilds automatically when favorites change via FavoritesService.

class SavedScreen extends StatelessWidget {
  final FavoritesService favoritesService;

  const SavedScreen({required this.favoritesService, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Saved Items',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: favoritesService,
        builder: (context, child) {
          final favorites = favoritesService.favorites;

          // Show empty state if no favorites
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No saved items yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Heart an item to save it here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Show list of favorites
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final itemTitle = favorites[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Placeholder image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 12),
                        // Item title
                        Expanded(
                          child: Text(
                            itemTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Remove from favorites button
                        IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // Remove from favorites when tapped
                            favoritesService.removeFavorite(itemTitle);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed "$itemTitle" from saved'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
