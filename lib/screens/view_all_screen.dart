import 'package:flutter/material.dart';
import '../widgets/giveaway_card.dart';
import '../widgets/available_item_tile.dart';
import '../services/favorites_service.dart';
import '../services/database_service.dart';
import 'item_detail_screen.dart';

/// View All Screen
///
/// Displays all items in a specific category (Give Away or Available Now)
/// with filtering and sorting options.
class ViewAllScreen extends StatefulWidget {
  final String categoryTitle;
  final String categoryType; // 'giveaway' or 'available'

  const ViewAllScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryType,
  });

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final DatabaseService _databaseService = DatabaseService();
  String _sortBy = 'Recent';
  bool _isGridView = false;

  final List<String> _sortOptions = ['Recent', 'Distance', 'Rating'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Toggle view button
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sortOptions.map((option) {
                        final isSelected = _sortBy == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _sortBy = option;
                              });
                            },
                            selectedColor: theme.primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.grey[700],
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List/Grid with FutureBuilder
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _databaseService.getPostsOnce(
                type: widget.categoryType,
                status: 'active',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error loading items: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No ${widget.categoryType} items yet.\nBe the first to post!',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return _isGridView 
                  ? _buildGridView(posts) 
                  : _buildListView(posts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> posts) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final title = post['title'] ?? 'Untitled';
        final rating = (post['rating'] ?? 0.0).toDouble();
        final location = post['location'] ?? 'Unknown';
        final imageUrls = List<String>.from(post['image_urls'] ?? []);
        final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

        return GiveAwayCard(
          title,
          rating,
          _favoritesService,
          imageUrl: imageUrl,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(
                  itemTitle: title,
                  rating: rating,
                  location: location,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> posts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final title = post['title'] ?? 'Untitled';
        final rating = (post['rating'] ?? 0.0).toDouble();
        final location = post['location'] ?? 'Unknown';
        final subtitle = '$location • ${rating.toStringAsFixed(1)} ★';
        final imageUrls = List<String>.from(post['image_urls'] ?? []);
        final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AvailableItemTile(
            title,
            subtitle,
            _favoritesService,
            imageUrl: imageUrl,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(
                    itemTitle: title,
                    rating: rating,
                    location: location,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
