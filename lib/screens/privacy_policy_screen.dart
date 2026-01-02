import 'package:flutter/material.dart';

/// Privacy Policy Screen
/// Displays the app's privacy policy and data handling information
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: December 29, 2025',
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
            title: '1. Information We Collect',
            content: '''We collect information that you provide directly to us, including:

• Account information (name, email, location)
• Profile information (bio, profile picture)
• Posts and listings you create
• Messages you send and receive
• Activity history and usage data
• Device information and IP address''',
          ),

          _buildSection(
            title: '2. How We Use Your Information',
            content: '''We use the information we collect to:

• Provide and maintain our services
• Connect you with other users
• Send notifications about your account
• Improve and personalize your experience
• Prevent fraud and ensure safety
• Comply with legal obligations''',
          ),

          _buildSection(
            title: '3. Information Sharing',
            content: '''We do not sell your personal information. We may share your information:

• With other users (profile, posts, messages)
• With service providers who assist our operations
• When required by law
• To protect our rights and safety
• With your consent''',
          ),

          _buildSection(
            title: '4. Data Security',
            content: '''We implement appropriate security measures to protect your information, including:

• Encrypted data transmission
• Secure data storage
• Access controls and authentication
• Regular security assessments

However, no method of transmission over the internet is 100% secure.''',
          ),

          _buildSection(
            title: '5. Your Rights',
            content: '''You have the right to:

• Access your personal data
• Correct inaccurate information
• Delete your account and data
• Export your data
• Opt-out of marketing communications
• Control notification settings''',
          ),

          _buildSection(
            title: '6. Data Retention',
            content: '''We retain your information for as long as your account is active or as needed to provide services. You may delete your account at any time, which will remove your personal information from our active databases.

Some information may be retained in backups for a limited time or as required by law.''',
          ),

          _buildSection(
            title: '7. Children\'s Privacy',
            content: '''Our service is not intended for users under 13 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.''',
          ),

          _buildSection(
            title: '8. Cookies and Tracking',
            content: '''We use cookies and similar technologies to:

• Keep you logged in
• Remember your preferences
• Analyze usage patterns
• Improve our services

You can control cookies through your browser settings.''',
          ),

          _buildSection(
            title: '9. Third-Party Services',
            content: '''We may use third-party services for:

• Authentication (Supabase)
• Cloud storage
• Analytics
• Push notifications

These services have their own privacy policies.''',
          ),

          _buildSection(
            title: '10. Changes to This Policy',
            content: '''We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.

Your continued use of the service after changes constitutes acceptance of the updated policy.''',
          ),

          _buildSection(
            title: '11. Contact Us',
            content: '''If you have questions about this privacy policy or our data practices, please contact us at:

Email: nemuellaid673@gmail.com
Address: Panabo City, Philippines''',
          ),

          const SizedBox(height: 32),

          // Accept Button (Optional)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('I Understand'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
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
    );
  }
}
