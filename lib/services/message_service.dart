import '../main.dart';
import '../models/message_model.dart';

/// Message Service
/// Handles all messaging operations with Supabase
class MessageService {
  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  /// Get or create a conversation between two users
  Future<String> getOrCreateConversation({
    required String otherUserId,
    String? postId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    // Check if conversation already exists between these users
    final existingConversation = await supabase
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', currentUserId!)
        .limit(1);

    if (existingConversation.isNotEmpty) {
      // Check if the other user is also in any of these conversations
      for (var conv in existingConversation) {
        final conversationId = conv['conversation_id'];
        final otherParticipant = await supabase
            .from('conversation_participants')
            .select()
            .eq('conversation_id', conversationId)
            .eq('user_id', otherUserId)
            .maybeSingle();

        if (otherParticipant != null) {
          return conversationId;
        }
      }
    }

    // Create new conversation
    final conversation = await supabase
        .from('conversations')
        .insert({
          'post_id': postId,
        })
        .select('id')
        .single();

    final conversationId = conversation['id'];

    // Add both participants
    await supabase.from('conversation_participants').insert([
      {
        'conversation_id': conversationId,
        'user_id': currentUserId,
      },
      {
        'conversation_id': conversationId,
        'user_id': otherUserId,
      },
    ]);

    return conversationId;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
    String messageType = 'text',
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    print('📤 Sending message to conversation: $conversationId');
    print('📤 Content: $content');
    print('📤 Sender: $currentUserId');

    final result = await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'content': content,
      'image_url': imageUrl,
      'message_type': messageType,
    }).select();

    print('✅ Message sent: $result');

    // Update conversation's updated_at timestamp
    await supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  /// Stream messages for a conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    print('📥 Streaming messages for conversation: $conversationId');
    
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((messages) async {
          print('📥 Received ${messages.length} messages from stream');
          List<ChatMessage> chatMessages = [];
          
          for (var message in messages) {
            final isSentByMe = message['sender_id'] == currentUserId;
            
            // Get sender's display name from profiles
            String senderName = 'User';
            if (!isSentByMe) {
              final profile = await supabase
                  .from('profiles')
                  .select('display_name, email')
                  .eq('id', message['sender_id'])
                  .maybeSingle();
              
              senderName = profile?['display_name'] ?? 
                           profile?['email']?.split('@')[0] ?? 
                           'User';
            } else {
              senderName = 'You';
            }
            
            chatMessages.add(ChatMessage(
              id: message['id'],
              text: message['content'] ?? '',
              timestamp: DateTime.parse(message['created_at']),
              isSentByMe: isSentByMe,
              senderName: senderName,
              senderAvatar: null,
              status: MessageStatus.read,
              imageUrl: message['image_url'],
              type: message['message_type'] == 'image' 
                  ? MessageType.image 
                  : MessageType.text,
            ));
          }
          
          print('✅ Converted to ${chatMessages.length} ChatMessage objects');
          return chatMessages;
        });
  }

  /// Get all conversations for current user
  Stream<List<Map<String, dynamic>>> getConversations() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return supabase
        .from('conversation_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .asyncMap((participants) async {
          List<Map<String, dynamic>> conversations = [];
          
          for (var participant in participants) {
            final conversationId = participant['conversation_id'];
            
            // Get conversation details
            final conversation = await supabase
                .from('conversations')
                .select()
                .eq('id', conversationId)
                .single();
            
            // Get other participant
            final otherParticipant = await supabase
                .from('conversation_participants')
                .select('user_id')
                .eq('conversation_id', conversationId)
                .neq('user_id', currentUserId!)
                .maybeSingle();
            
            if (otherParticipant == null) continue;
            
            // Get other user's profile
            final otherUserProfile = await supabase
                .from('profiles')
                .select('display_name, avatar_url')
                .eq('id', otherParticipant['user_id'])
                .maybeSingle();
            
            // Get last message
            final lastMessage = await supabase
                .from('messages')
                .select()
                .eq('conversation_id', conversationId)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
            
            // Count unread messages
            final unreadCount = await supabase
                .from('messages')
                .select()
                .eq('conversation_id', conversationId)
                .neq('sender_id', currentUserId!)
                .then((messages) {
                  return messages.where((msg) {
                    final readBy = msg['read_by'] as List?;
                    return readBy == null || !readBy.contains(currentUserId);
                  }).length;
                });
            
            conversations.add({
              'id': conversationId,
              'other_user_id': otherParticipant['user_id'],
              'other_user_name': otherUserProfile?['display_name'] ?? 'User',
              'other_user_avatar': otherUserProfile?['avatar_url'],
              'last_message': lastMessage?['content'] ?? '',
              'last_message_time': lastMessage?['created_at'],
              'unread_count': unreadCount,
              'updated_at': conversation['updated_at'],
            });
          }
          
          // Sort by updated_at
          conversations.sort((a, b) {
            final aTime = DateTime.parse(a['updated_at']);
            final bTime = DateTime.parse(b['updated_at']);
            return bTime.compareTo(aTime);
          });
          
          return conversations;
        });
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    if (currentUserId == null) return;

    final messages = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId!);

    for (var message in messages) {
      final readBy = List<String>.from(message['read_by'] ?? []);
      if (!readBy.contains(currentUserId)) {
        readBy.add(currentUserId!);
        await supabase
            .from('messages')
            .update({'read_by': readBy})
            .eq('id', message['id']);
      }
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await supabase
        .from('profiles')
        .select('display_name, avatar_url, email')
        .eq('id', userId)
        .maybeSingle();
  }
}
