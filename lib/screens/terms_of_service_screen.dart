import 'package:flutter/material.dart';

/// Terms of Service Screen
/// Displays the app's terms and conditions
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: January 2, 2026',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _buildSection(
            title: '1. Acceptance of Terms',
            content: '''By downloading, installing, or using the Declutter app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.

These terms apply to all users of the app, including browsers, posters, and other contributors of content.''',
          ),

          _buildSection(
            title: '2. Description of Service',
            content: '''Declutter is a community-driven platform that enables users to:

• Share items they no longer need (giveaways)
• Browse and request available items
• Communicate with other users
• Build a sustainable community

The service is provided free of charge and is intended for personal, non-commercial use.''',
          ),

          _buildSection(
            title: '3. User Accounts',
            content: '''To use certain features, you must create an account. You agree to:

• Provide accurate and complete information
• Maintain the security of your account credentials
• Accept responsibility for all activities under your account
• Notify us immediately of any unauthorized use

We reserve the right to suspend or terminate accounts that violate these terms.''',
          ),

          _buildSection(
            title: '4. User Conduct',
            content: '''You agree NOT to:

• Post false, misleading, or fraudulent content
• Harass, threaten, or harm other users
• Use the service for commercial purposes without permission
• Post illegal, offensive, or inappropriate content
• Attempt to hack or disrupt the service
• Impersonate other users or entities
• Spam or send unsolicited messages

Violations may result in immediate account termination.''',
          ),

          _buildSection(
            title: '5. Content Guidelines',
            content: '''When posting items, you must:

• Only post items you own or have permission to give away
• Provide accurate descriptions and photos
• Not post prohibited items (weapons, drugs, stolen goods, etc.)
• Respond to inquiries in a timely manner

We reserve the right to remove any content that violates these guidelines.''',
          ),

          _buildSection(
            title: '6. Transactions',
            content: '''Declutter facilitates connections between users but is NOT responsible for:

• The quality or condition of items
• Completion of transactions
• Disputes between users
• Personal safety during meetups

Users are encouraged to meet in public places and exercise caution.''',
          ),

          _buildSection(
            title: '7. Intellectual Property',
            content: '''The Declutter app, including its design, features, and content, is protected by intellectual property laws.

You retain ownership of content you post, but grant us a license to display and distribute it within the app.

You may not copy, modify, or distribute our app or its content without permission.''',
          ),

          _buildSection(
            title: '8. Limitation of Liability',
            content: '''Declutter is provided "as is" without warranties of any kind.

We are not liable for:
• Loss or damage from using the service
• Actions of other users
• Technical issues or service interruptions
• Loss of data or content

Use the service at your own risk.''',
          ),

          _buildSection(
            title: '9. Changes to Terms',
            content: '''We may update these Terms of Service at any time. Continued use of the app after changes constitutes acceptance of the new terms.

We will notify users of significant changes through the app or email.''',
          ),

          _buildSection(
            title: '10. Contact Us',
            content: '''If you have questions about these Terms of Service, please contact us:

Email: nemuellaid673@gmail.com

Thank you for being part of the Declutter community!''',
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
