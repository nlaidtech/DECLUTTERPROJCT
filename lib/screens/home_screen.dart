import 'package:flutter/material.dart';

// This file builds the Home screen layout and composes smaller widgets from
// `lib/widgets/*` for clarity and reusability. Each widget file contains its
// own inline documentation explaining purpose and behavior.

import '../widgets/category_button.dart';
import '../widgets/giveaway_card.dart';
import '../widgets/available_item_tile.dart';
import '../services/favorites_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // Access the singleton FavoritesService instance
  final FavoritesService favoritesService = FavoritesService();

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        // Saved screen
        Navigator.pushNamed(context, '/saved');
        setState(() => _selectedIndex = 0); // Reset tab after navigation
        break;
      case 2:
        // Add item - placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add item feature coming soon!')),
        );
        break;
      case 3:
        // Messages - placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Messages feature coming soon!')),
        );
        break;
      case 4:
        // Profile - placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile feature coming soon!')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The main scaffold and overall layout remain similar to the original.
    // We now use dedicated widgets for categories, cards and tiles so each
    // piece is easier to test and extend.
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Declutter', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('PANABO', style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Find the best to give', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Share items you don\'t need anymore', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Search bar (unchanged behavior)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Search items', style: TextStyle(color: Colors.grey[500]))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categories - composed using the reusable `CategoryButton` widget.
              const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    CategoryButton('Sports', Icons.directions_bike, Colors.green),
                    CategoryButton('Electronics', Icons.electrical_services, Colors.purple),
                    CategoryButton('Tools', Icons.build, Colors.orange),
                    CategoryButton('Furniture', Icons.chair, Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Give Away section - uses `GiveAwayCard` which now connects to
              // FavoritesService to sync heart state globally.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Give Away', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(color: Colors.blue))),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GiveAwayCard('Base Camp Tent', 4.9, favoritesService),
                    GiveAwayCard('Google Pixel Tablet', 4.1, favoritesService),
                    GiveAwayCard('Stainless Pot', 4.0, favoritesService),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Available now list - uses `AvailableItemTile` which now connects
              // to FavoritesService. Tap the heart to save to Saved screen.
              const Text('Available now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AvailableItemTile('Craftsman Cordless Drill', '4.0 km away • 4.9 ★', favoritesService),
              const SizedBox(height: 12),
              AvailableItemTile('Office Chair', '2.5 km away • 4.3 ★', favoritesService),
              const SizedBox(height: 12),
              AvailableItemTile('Portable Speaker', '3.2 km away • 4.5 ★', favoritesService),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
