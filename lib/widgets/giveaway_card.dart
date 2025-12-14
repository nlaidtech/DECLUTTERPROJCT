import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

/// GiveAwayCard
///
/// A card widget representing an item being given away. This widget uses
/// FavoritesService to manage the heart (favorite) state globally. When the
/// user taps the heart, the item is added/removed from the Saved screen.
class GiveAwayCard extends StatelessWidget {
  final String title;
  final double rating;
  final FavoritesService favoritesService;

  const GiveAwayCard(this.title, this.rating, this.favoritesService, {super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds this widget whenever favoritesService changes.
    // This ensures the heart icon reflects the current favorite state.
    return ListenableBuilder(
      listenable: favoritesService,
      builder: (context, _) {
        final isFavorited = favoritesService.isFavorite(title);
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Icon(Icons.image, color: Colors.grey[400], size: 40),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber[600]),
                            const SizedBox(width: 4),
                            Text(rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        // Heart icon calls favoritesService.toggleFavorite() when tapped.
                        // The icon updates instantly via ListenableBuilder rebuild.
                        IconButton(
                          icon: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFavorited ? Colors.red : Colors.grey[400],
                          ),
                          onPressed: () => favoritesService.toggleFavorite(title),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
