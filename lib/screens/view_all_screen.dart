import 'package:flutter/material.dart';
import '../widgets/giveaway_card.dart';
import '../widgets/available_item_tile.dart';
import '../services/favorites_service.dart';

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
  String _sortBy = 'Recent';
  bool _isGridView = false;

  final List<String> _sortOptions = ['Recent', 'Distance', 'Rating'];

  // Sample items for demonstration
  final List<Map<String, dynamic>> _giveawayItems = [
    {'name': 'Base Camp Tent', 'rating': 4.9, 'distance': '2.3 km'},
    {'name': 'Google Pixel Tablet', 'rating': 4.1, 'distance': '3.5 km'},
    {'name': 'Stainless Pot', 'rating': 4.0, 'distance': '1.8 km'},
    {'name': 'Mountain Bike', 'rating': 4.7, 'distance': '4.2 km'},
    {'name': 'Desk Lamp', 'rating': 4.5, 'distance': '2.9 km'},
    {'name': 'Bookshelf', 'rating': 4.3, 'distance': '3.1 km'},
    {'name': 'Running Shoes', 'rating': 4.6, 'distance': '1.5 km'},
    {'name': 'Coffee Maker', 'rating': 4.4, 'distance': '2.7 km'},
  ];

  final List<Map<String, dynamic>> _availableItems = [
    {'name': 'Craftsman Cordless Drill', 'rating': 4.9, 'distance': '4.0 km'},
    {'name': 'Office Chair', 'rating': 4.3, 'distance': '2.5 km'},
    {'name': 'Portable Speaker', 'rating': 4.5, 'distance': '3.2 km'},
    {'name': 'Gaming Console', 'rating': 4.8, 'distance': '5.1 km'},
    {'name': 'Electric Kettle', 'rating': 4.2, 'distance': '1.9 km'},
    {'name': 'Table Lamp', 'rating': 4.6, 'distance': '3.7 km'},
    {'name': 'Yoga Mat', 'rating': 4.4, 'distance': '2.2 km'},
    {'name': 'Bluetooth Headphones', 'rating': 4.7, 'distance': '4.5 km'},
  ];

  List<Map<String, dynamic>> get _items =>
      widget.categoryType == 'giveaway' ? _giveawayItems : _availableItems;

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

          // Items count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_items.length} items found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Items List/Grid
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return GiveAwayCard(
          item['name'],
          item['rating'].toDouble(),
          _favoritesService,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AvailableItemTile(
            item['name'],
            '${item['distance']} away • ${item['rating']} ★',
            _favoritesService,
          ),
        );
      },
    );
  }
}
