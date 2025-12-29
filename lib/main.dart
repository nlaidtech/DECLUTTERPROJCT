import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'services/favorites_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const MyApp());
}

// Global Supabase client instance - access anywhere with: supabase.auth, supabase.from(), etc.
final supabase = Supabase.instance.client;

// Root widget of the application - now Stateful to show welcome dialog on first run
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // FavoritesService is now a singleton, accessible globally via FavoritesService()

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Declutter',
      // Configure app theme with green as primary color
      theme: AppTheme.lightTheme,
      // Initial route displayed when app starts - calls login_screen.dart
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(
              onSwitchToSignUp: () => Navigator.pushNamed(context, '/signup'),
            ),
        '/signup': (context) => SignUpScreen(
              onSwitchToLogin: () => Navigator.pop(context),
            ),
        '/forgot-password': (context) => ForgotPasswordScreen(
              onBackToLogin: () => Navigator.pop(context),
            ),
        '/home': (context) => const HomeScreen(),
        '/saved': (context) => SavedScreen(favoritesService: FavoritesService()),
        '/message': (context) => const ConversationsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/search': (context) => const SearchScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}

