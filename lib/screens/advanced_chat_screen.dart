import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

/// Advanced Chat Screen - Production-Ready Implementation
/// 
/// Features:
/// - Real-time messaging with Supabase
/// - Material Design 3 with theme support
/// - Message status indicators (sent, delivered, read)
/// - Date separators between different days
/// - Smooth animations and 60fps performance
/// - Auto-scroll to bottom for new messages
/// - Avatar support for received messages
class AdvancedChatScreen extends StatefulWidget {
  final String chatId; // Can be user ID or conversation ID
  final String recipientName;
  final String? recipientAvatar;
  final String? postId; // Optional: link conversation to a specific post

  const AdvancedChatScreen({
    super.key,
    required this.chatId,
    required this.recipientName,
    this.recipientAvatar,
    this.postId,
  });

  @override
  State<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final MessageService _messageService = MessageService();

  // State
  String? _conversationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
    _listenToKeyboard();
  }

  /// Initialize or get existing conversation
  Future<void> _initializeConversation() async {
    try {
      // Extract user ID from chatId (format: 'chat_<userId>')
      final otherUserId = widget.chatId.replaceFirst('chat_', '');
      
      // Get or create conversation
      _conversationId = await _messageService.getOrCreateConversation(
        otherUserId: otherUserId,
        postId: widget.postId,
      );
      
      // Mark messages as read
      await _messageService.markAsRead(_conversationId!);
      
      setState(() => _isLoading = false);
      
      // Scroll to bottom after loading
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  /// Listen to keyboard events for smooth UX
  void _listenToKeyboard() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Send a new message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _conversationId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _messageService.sendMessage(
        conversationId: _conversationId!,
        content: messageText,
      );
      
      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  /// Smooth scroll to bottom of chat
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Check if we need a date separator before this message
  bool _shouldShowDateSeparator(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;
    return current.year != previous.year ||
           current.month != previous.month ||
           current.day != previous.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.primaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.recipientName),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          // Messages list with StreamBuilder
          Expanded(
            child: _conversationId == null
                ? const Center(child: Text('Unable to load conversation'))
                : StreamBuilder<List<ChatMessage>>(
                    stream: _messageService.getMessages(_conversationId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!;

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet. Start the conversation!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      // Auto-scroll to bottom when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Column(
                            children: [
                              // Date separator
                              if (_shouldShowDateSeparator(messages, index))
                                _DateSeparator(date: message.formattedDate),
                              
                              // Message bubble
                              _MessageBubble(
                                message: message,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),

          // Message input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  /// Build app bar with user info
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.primaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary,
            child: widget.recipientAvatar != null
                ? null
                : Text(
                    widget.recipientName[0].toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              widget.recipientName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  /// Build message input field
  Widget _buildMessageInput(ThemeData theme) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Emoji/Attachment button
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
              onPressed: () {
                // Show attachment options
              },
            ),
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {},
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Material(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date separator widget
class _DateSeparator extends StatelessWidget {
  final String date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

/// Message bubble widget with status indicators
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSent = message.isSentByMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSent
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isSent ? 20 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSent
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Time and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display relative time (e.g., "2 hours ago", "14 hours ago")
                      StreamBuilder<int>(
                        stream: Stream.periodic(const Duration(seconds: 10), (count) => count),
                        builder: (context, snapshot) {
                          return Text(
                            message.relativeTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSent
                                  ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                  : theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == MessageStatus.read
                              ? Icons.done_all
                              : message.status == MessageStatus.delivered
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 16,
                          color: message.status == MessageStatus.read
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isSent) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
