import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

/// AvailableItemTile
///
/// A tile widget representing an available item. It uses FavoritesService to
/// manage the heart (favorite) state globally. When the user taps the heart,
/// the item is added/removed from the Saved screen.
class AvailableItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final FavoritesService favoritesService;

  const AvailableItemTile(this.title, this.subtitle, this.favoritesService, {super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds when favoritesService changes.
    return ListenableBuilder(
      listenable: favoritesService,
      builder: (context, _) {
        final isFavorited = favoritesService.isFavorite(title);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.image, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              // Heart icon toggles favorite status via favoritesService.
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : Colors.grey[400],
                ),
                onPressed: () => favoritesService.toggleFavorite(title),
              ),
            ],
          ),
        );
      },
    );
  }
}
