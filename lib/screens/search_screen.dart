import 'package:flutter/material.dart';
import '../widgets/available_item_tile.dart';
import '../services/favorites_service.dart';
import '../services/database_service.dart';
import 'item_detail_screen.dart';

/// Search Screen
///
/// Allows users to search for items by keywords from the database.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = query.isNotEmpty;
      _isLoading = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Search in database for posts matching the query
      final results = await _databaseService.searchPosts(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Items',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search items near you',
                prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_isSearching) {
      // Show instruction when not searching
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for items',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type to find posts by title or description',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      // Show empty state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Show search results
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        final title = post['title'] ?? 'Untitled';
        final description = post['description'] as String?;
        final location = post['location'] ?? 'Unknown';
        final postId = post['id'];
        final userId = post['user_id'];
        final imageUrls = List<String>.from(post['image_urls'] ?? []);
        final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
        final latitude = (post['latitude'] as num?)?.toDouble();
        final longitude = (post['longitude'] as num?)?.toDouble();
        
        // Get user profile data
        final userProfile = post['profiles'] as Map<String, dynamic>?;
        final userName = userProfile?['display_name'] ?? 
                       userProfile?['email']?.split('@')[0] ?? 
                       'User';
        final userEmail = userProfile?['email'];
        final userPhotoUrl = userProfile?['photo_url'];
        final memberSince = userProfile?['created_at'] != null 
            ? DateTime.parse(userProfile!['created_at'])
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AvailableItemTile(
            title,
            location,
            _favoritesService,
            imageUrl: imageUrl,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(
                    itemTitle: title,
                    itemDescription: description,
                    location: location,
                    postId: postId,
                    userId: userId,
                    userName: userName,
                    userEmail: userEmail,
                    userPhotoUrl: userPhotoUrl,
                    memberSince: memberSince,
                    imageUrls: imageUrls,
                    latitude: latitude,
                    longitude: longitude,
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
