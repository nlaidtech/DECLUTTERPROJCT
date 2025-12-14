import 'package:flutter/material.dart';

// Welcome Dialog - Displayed to first-time users of the app
class WelcomeDialog extends StatelessWidget {
  // Callback function when user closes the dialog
  final VoidCallback onClose;

  const WelcomeDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Set shape of dialog to rounded rectangle
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Remove default dialog padding
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        // Set fixed width and height for dialog
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Gradient background from green to lighter green
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[600]!, Colors.green[400]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome icon - Large circular icon at top
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                ),
                child: const Icon(
                  Icons.done_all,
                  size: 40,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              // Welcome title
              const Text(
                'Welcome to Declutter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Welcome subtitle - Description of app purpose
              Text(
                'Your personal organizer app to manage and declutter your life',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 24),

              // Key features bullet points
              _buildFeature(Icons.security, 'Secure & Private'),
              const SizedBox(height: 12),
              _buildFeature(Icons.speed, 'Fast & Easy'),
              const SizedBox(height: 12),
              _buildFeature(Icons.cloud_sync, 'Synchronized'),
              const SizedBox(height: 28),

              // Get Started button - Closes dialog and proceeds to login
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build feature list items
  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        // Feature icon
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        // Feature text
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
