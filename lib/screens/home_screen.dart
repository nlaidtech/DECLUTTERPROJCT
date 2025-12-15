import 'package:flutter/material.dart';
import '../widgets/category_button.dart';
import '../widgets/giveaway_card.dart';
import '../widgets/available_item_tile.dart';
import '../services/favorites_service.dart';
import 'create_post_screen.dart';

/// ---------- COLOR SYSTEM ----------
const Color primaryGreen = Color(0xFF4CAF50);
const Color lightGreen = Color(0xFFE8F5E9);
const Color accentOrange = Color(0xFFFF9800);
const Color background = Color(0xFFF4F7F5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FavoritesService favoritesService = FavoritesService();

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile feature coming soon')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Declutter',
          style: TextStyle(
            color: primaryGreen,
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Declutter your space',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Give items a second life',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------- SEARCH BAR ----------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: primaryGreen),
                  const SizedBox(width: 12),
                  Text(
                    'Search items near you',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
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
                children: const [
                  CategoryButton('Sports', Icons.directions_bike, primaryGreen),
                  CategoryButton('Electronics', Icons.electrical_services, Colors.purple),
                  CategoryButton('Tools', Icons.build, accentOrange),
                  CategoryButton('Furniture', Icons.chair, Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------- GIVE AWAY SECTION ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightGreen,
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
                        onPressed: () {},
                        child: const Text(
                          'View all',
                          style: TextStyle(color: primaryGreen),
                        ),
                      ),
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
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------- AVAILABLE NOW ----------
            const Text(
              'Available now',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentOrange,
              ),
            ),
            const SizedBox(height: 12),
            AvailableItemTile(
              'Craftsman Cordless Drill',
              '4.0 km away • 4.9 ★',
              favoritesService,
            ),
            const SizedBox(height: 12),
            AvailableItemTile(
              'Office Chair',
              '2.5 km away • 4.3 ★',
              favoritesService,
            ),
            const SizedBox(height: 12),
            AvailableItemTile(
              'Portable Speaker',
              '3.2 km away • 4.5 ★',
              favoritesService,
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),

      // ---------- FLOATING ADD BUTTON ----------
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Post Item',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
        color: isActive ? primaryGreen : Colors.grey.shade400,
      ),
    );
  }
}
