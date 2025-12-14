import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/welcome_dialog.dart';
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
  // Create a single instance of FavoritesService to share across the app
  final favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  // Check SharedPreferences to determine if welcome dialog should be shown
  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_welcome') ?? false;
    if (!seen && mounted) {
      // Show after first frame so context is available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => WelcomeDialog(onClose: () async {
            Navigator.of(context).pop();
            await prefs.setBool('seen_welcome', true);
          }),
        );
      });
    }
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
        '/home': (context) => HomeScreen(favoritesService: favoritesService),
        '/saved': (context) => SavedScreen(favoritesService: favoritesService),
      },
    );
  }
}

