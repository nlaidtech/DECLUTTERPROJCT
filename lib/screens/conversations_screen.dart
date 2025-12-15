import 'package:flutter/material.dart';
import 'advanced_chat_screen.dart';

/// Conversations List Screen
/// 
/// Shows all active chat conversations with different people
/// Each conversation can be tapped to open individual chat
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Messages'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // Conversation with John Doe
          _ConversationTile(
            name: 'John Doe',
            lastMessage: 'Perfect! I\'ll come by at 3:30 PM',
            timestamp: '2 min ago',
            unreadCount: 2,
            avatarInitial: 'J',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedChatScreen(
                    chatId: 'chat_john',
                    recipientName: 'John Doe',
                  ),
                ),
              );
            },
          ),
          
          // Conversation with Maria Santos
          _ConversationTile(
            name: 'Maria Santos',
            lastMessage: 'Hey, I\'m also interested! Is it still available?',
            timestamp: '15 min ago',
            unreadCount: 1,
            avatarInitial: 'M',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedChatScreen(
                    chatId: 'chat_maria',
                    recipientName: 'Maria Santos',
                  ),
                ),
              );
            },
          ),
          
          // Additional sample conversations
          _ConversationTile(
            name: 'Alex Chen',
            lastMessage: 'Thanks for the lamp! It looks great 💡',
            timestamp: '1 hour ago',
            unreadCount: 0,
            avatarInitial: 'A',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedChatScreen(
                    chatId: 'chat_alex',
                    recipientName: 'Alex Chen',
                  ),
                ),
              );
            },
          ),
          
          _ConversationTile(
            name: 'Sarah Johnson',
            lastMessage: 'Is the bookshelf still available?',
            timestamp: 'Yesterday',
            unreadCount: 0,
            avatarInitial: 'S',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedChatScreen(
                    chatId: 'chat_sarah',
                    recipientName: 'Sarah Johnson',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      
      // Floating action button to start new conversation
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open new conversation dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New conversation feature coming soon!')),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}

/// Individual conversation tile in the list
class _ConversationTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final String avatarInitial;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.avatarInitial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                avatarInitial,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      // Timestamp
                      Text(
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasUnread
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Last message
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Unread badge
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}