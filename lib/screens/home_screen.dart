import 'package:flutter/material.dart';
import '../widgets/giveaway_card.dart';
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
        Navigator.pushNamed(context, '/message');
        break;
      case 2:
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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _databaseService.getPosts(
                      type: 'giveaway',
                      status: 'active',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Giveaway error: ${snapshot.error}');
                        // Fallback to FutureBuilder if realtime fails
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: _databaseService.getPostsOnce(
                            type: 'giveaway',
                            status: 'active',
                          ),
                          builder: (context, futureSnapshot) {
                            if (futureSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final posts = futureSnapshot.data ?? [];
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
                                  final description = data['description'] as String?;
                                  final location = data['location'] ?? 'Unknown';
                                  final postId = data['id'];
                                  final userId = data['user_id'];
                                  final imageUrls = List<String>.from(data['image_urls'] ?? []);
                                  final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
                                  final latitude = (data['latitude'] as num?)?.toDouble();
                                  final longitude = (data['longitude'] as num?)?.toDouble();
                                  final userProfile = data['profiles'] as Map<String, dynamic>?;
                                  final userName = userProfile?['display_name'] ?? userProfile?['email']?.split('@')[0] ?? 'User';
                                  final userEmail = userProfile?['email'];
                                  final userPhotoUrl = userProfile?['photo_url'];
                                  final memberSince = userProfile?['created_at'] != null ? DateTime.parse(userProfile!['created_at']) : null;
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
                                  );
                                }).toList(),
                              ),
                            );
                          },
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
                            final description = data['description'] as String?;
                            final location = data['location'] ?? 'Unknown';
                            final postId = data['id'];
                            final userId = data['user_id'];
                            final imageUrls = List<String>.from(
                              data['image_urls'] ?? [],
                            );
                            final imageUrl = imageUrls.isNotEmpty
                                ? imageUrls.first
                                : null;
                            final latitude = (data['latitude'] as num?)?.toDouble();
                            final longitude = (data['longitude'] as num?)?.toDouble();
                            
                            // Get user profile data from the joined profiles table
                            final userProfile = data['profiles'] as Map<String, dynamic>?;
                            final userName = userProfile?['display_name'] ?? 
                                           userProfile?['email']?.split('@')[0] ?? 
                                           'User';
                            final userEmail = userProfile?['email'];
                            final userPhotoUrl = userProfile?['photo_url'];
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
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
                icon: Icons.chat_bubble,
                outlinedIcon: Icons.chat_bubble_outline,
                isActive: _selectedIndex == 1,
                onTap: () => _onNavItemTapped(1),
              ),
              _NavIcon(
                icon: Icons.person,
                outlinedIcon: Icons.person_outline,
                isActive: _selectedIndex == 2,
                onTap: () => _onNavItemTapped(2),
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
