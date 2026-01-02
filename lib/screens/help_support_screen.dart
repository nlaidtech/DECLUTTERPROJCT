import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help & Support Screen
/// Provides users with help resources and support options
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'nemuellaid673@gmail.com',
      query: 'subject=Declutter App - Help Request',
    );
    
    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app. Please email nemuellaid673@gmail.com'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Please email nemuellaid673@gmail.com'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers to common questions or get in touch',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFAQItem(
                  question: 'How do I post an item?',
                  answer: 'Tap the + button on the home screen, fill in the item details, add photos, and tap Publish.',
                ),
                _buildFAQItem(
                  question: 'How do I save items?',
                  answer: 'Tap the bookmark icon on any item to save it to your favorites. View saved items from the bottom navigation.',
                ),
                _buildFAQItem(
                  question: 'How do I contact someone?',
                  answer: 'Open an item and tap the Message button to start a conversation with the item owner.',
                ),
                _buildFAQItem(
                  question: 'How do I delete my post?',
                  answer: 'Go to Profile > My Posts, tap on the post you want to delete, then tap the delete icon.',
                ),
                _buildFAQItem(
                  question: 'Is this service free?',
                  answer: 'Yes! Declutter is completely free to use. Our mission is to help reduce waste by connecting people.',
                ),
                _buildFAQItem(
                  question: 'How do I change my location?',
                  answer: 'Go to Profile > Edit Profile to update your location settings.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Support
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email Support'),
                    subtitle: const Text('nemuellaid673@gmail.com'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _launchEmail(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
