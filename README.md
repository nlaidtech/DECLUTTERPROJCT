# Declutter App 🌱

A **community-based giveaway/sharing platform** where users can give away items they no longer need instead of throwing them out. Built with Flutter.

## About

Declutter promotes sustainability by helping people declutter their homes while giving items a second life. Instead of discarding usable items, users can share them with others in their community.

## Key Features

### 🏠 Home Screen
- Browse items available for giveaway
- Search functionality
- Categories (Furniture, Electronics, Clothes, Books, Sports, Toys)
- Featured "GiveAway Cards" with ratings
- List of available items with location info

### 💚 Saved/Favorites
- Heart/favorite items to save them for later
- Global favorites service tracks saved items
- Dedicated saved items screen

### 📱 Navigation
- Home feed
- Saved items
- Add item (coming soon)
- Messages (coming soon)
- Profile (coming soon)

### 🔐 Authentication
- Login screen
- Sign up screen
- Forgot password functionality
- User model with ID, name, email, password

## Tech Stack

- **Framework:** Flutter
- **Design:** Material Design 3
- **Theme:** Green color scheme (eco-friendly)
- **State Management:** ChangeNotifier for favorites service

## Getting Started

### Prerequisites
- Flutter SDK 3.35.7 or higher
- Dart SDK
- Android SDK (for Android builds)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd declutter_project
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── user_model.dart      # User data model
├── screens/
│   ├── home_screen.dart     # Main home feed
│   ├── login_screen.dart    # Login page
│   ├── signup_screen.dart   # Sign up page
│   ├── saved_screen.dart    # Saved items
│   └── forgot_password_screen.dart
├── services/
│   └── favorites_service.dart  # Global favorites management
└── widgets/
    ├── available_item_tile.dart
    ├── category_button.dart
    ├── giveaway_card.dart
    └── message_button.dart
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
