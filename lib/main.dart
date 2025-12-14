import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'services/favorites_service.dart';

void main() {
  runApp(const MyApp());
}

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
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
      },
    );
  }
}

