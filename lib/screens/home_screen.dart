import 'package:flutter/material.dart';
import '../widgets/category_button.dart';
import '../widgets/giveaway_card.dart';
import '../widgets/available_item_tile.dart';
import '../services/favorites_service.dart';
import '../services/database_service.dart';
import 'create_post_screen.dart';
import 'view_all_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FavoritesService favoritesService = FavoritesService();
  final DatabaseService _databaseService = DatabaseService();

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.pushNamed(context, '/saved');
        break;
      case 3:
        Navigator.pushNamed(context, '/message');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Declutter',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'PANABO',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HERO SECTION ----------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Declutter your space',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Give items a second life',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------- SEARCH BAR ----------
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/search');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Search items near you',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ---------- CATEGORIES ----------
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryButton(
                    'Sports',
                    Icons.directions_bike,
                    Theme.of(context).primaryColor,
                  ),
                  const CategoryButton(
                    'Electronics',
                    Icons.electrical_services,
                    Colors.purple,
                  ),
                  CategoryButton(
                    'Tools',
                    Icons.build,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  const CategoryButton('Furniture', Icons.chair, Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------- GIVE AWAY SECTION ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Give Away',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewAllScreen(
                                categoryTitle: 'Give Away',
                                categoryType: 'giveaway',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'View all',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _databaseService.getPostsOnce(
                      type: 'giveaway',
                      status: 'active',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Giveaway error: ${snapshot.error}');
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = snapshot.data ?? [];

                      if (posts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No giveaway items yet. Be the first to post!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: posts.take(5).map((data) {
                            final title = data['title'] ?? 'Untitled';
                            final location = data['location'] ?? 'Unknown';
                            final postId = data['id'];
                            final userId = data['user_id'];
                            final imageUrls = List<String>.from(
                              data['image_urls'] ?? [],
                            );
                            final imageUrl = imageUrls.isNotEmpty
                                ? imageUrls.first
                                : null;
                            
                            // Get user profile data from the joined profiles table
                            final userProfile = data['profiles'] as Map<String, dynamic>?;
                            final userName = userProfile?['display_name'] ?? 
                                           userProfile?['email']?.split('@')[0] ?? 
                                           'User';
                            final userEmail = userProfile?['email'];
                            final memberSince = userProfile?['created_at'] != null 
                                ? DateTime.parse(userProfile!['created_at'])
                                : null;

                            return GiveAwayCard(
                              title,
                              favoritesService,
                              imageUrl: imageUrl,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ItemDetailScreen(
                                      itemTitle: title,
                                      location: location,
                                      postId: postId,
                                      userId: userId,
                                      userName: userName,
                                      userEmail: userEmail,
                                      memberSince: memberSince,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------- AVAILABLE NOW ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available now',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewAllScreen(
                          categoryTitle: 'Available Now',
                          categoryType: 'available',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _databaseService.getPostsOnce(
                type: 'available',
                status: 'active',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Available error: ${snapshot.error}');
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No available items yet. Post something to share!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: posts.take(3).map((data) {
                    final title = data['title'] ?? 'Untitled';
                    final location = data['location'] ?? 'Unknown';
                    final postId = data['id'];
                    final userId = data['user_id'];
                    final subtitle = location;
                    final imageUrls = List<String>.from(
                      data['image_urls'] ?? [],
                    );
                    final imageUrl = imageUrls.isNotEmpty
                        ? imageUrls.first
                        : null;
                    
                    // Get user profile data from the joined profiles table
                    final userProfile = data['profiles'] as Map<String, dynamic>?;
                    final userName = userProfile?['display_name'] ?? 
                                   userProfile?['email']?.split('@')[0] ?? 
                                   'User';
                    final userEmail = userProfile?['email'];
                    final memberSince = userProfile?['created_at'] != null 
                        ? DateTime.parse(userProfile!['created_at'])
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AvailableItemTile(
                        title,
                        subtitle,
                        favoritesService,
                        imageUrl: imageUrl,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(
                                itemTitle: title,
                                location: location,
                                postId: postId,
                                userId: userId,
                                userName: userName,
                                userEmail: userEmail,
                                memberSince: memberSince,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),

      // ---------- FLOATING ADD BUTTON ----------
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Post Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ---------- BOTTOM NAV ----------
      bottomNavigationBar: BottomAppBar(
        elevation: 12,
        color: Colors.white,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home,
                outlinedIcon: Icons.home_outlined,
                isActive: _selectedIndex == 0,
                onTap: () => _onNavItemTapped(0),
              ),
              _NavIcon(
                icon: Icons.favorite,
                outlinedIcon: Icons.favorite_border,
                isActive: _selectedIndex == 1,
                onTap: () => _onNavItemTapped(1),
              ),
              _NavIcon(
                icon: Icons.chat_bubble,
                outlinedIcon: Icons.chat_bubble_outline,
                isActive: _selectedIndex == 3,
                onTap: () => _onNavItemTapped(3),
              ),
              _NavIcon(
                icon: Icons.person,
                outlinedIcon: Icons.person_outline,
                isActive: _selectedIndex == 4,
                onTap: () => _onNavItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- NAV ICON ----------
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.outlinedIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isActive ? icon : outlinedIcon,
        color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade400,
      ),
    );
  }
}
