import '../main.dart';
import '../models/message_model.dart';

/// Message Service
/// Handles all messaging operations with Supabase
class MessageService {
  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  /// Get or create a conversation between two users
  /// 
  /// This function implements a smart conversation lookup:
  /// 1. First checks if a conversation already exists between the two users
  /// 2. If found, returns the existing conversation ID
  /// 3. If not found, creates a new conversation and adds both users as participants
  /// 
  /// Why this matters: Prevents duplicate conversations between same users
  /// 
  /// Parameters:
  /// - otherUserId: The ID of the user you want to chat with
  /// - postId: (Optional) If the conversation is about a specific post
  /// 
  /// Returns: The conversation ID (either existing or newly created)
  Future<String> getOrCreateConversation({
    required String otherUserId,
    String? postId,
  }) async {
    // Validate user is logged in
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    print('🔍 Looking for existing conversation between $currentUserId and $otherUserId');

    // STEP 1: Find all conversations where current user is a participant
    // Query the conversation_participants table to get all conversation IDs
    // where the current user is involved
    final myConversations = await supabase
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', currentUserId!);

    print('📋 Current user is in ${myConversations.length} conversations');

    // STEP 2: Check if the other user is also in any of these conversations
    // Loop through each conversation the current user is in
    if (myConversations.isNotEmpty) {
      for (var conv in myConversations) {
        final conversationId = conv['conversation_id'];
        
        // Check if the other user is ALSO a participant in this conversation
        // If yes, it means a conversation already exists between these two users
        final otherParticipant = await supabase
            .from('conversation_participants')
            .select()
            .eq('conversation_id', conversationId)
            .eq('user_id', otherUserId)
            .maybeSingle();

        // Found a conversation where both users are participants!
        if (otherParticipant != null) {
          print('✅ Found existing conversation: $conversationId');
          return conversationId;  // Return existing conversation ID
        }
      }
    }

    // STEP 3: No existing conversation found, create a new one
    print('📝 Creating new conversation');

    // Insert a new conversation record
    final conversation = await supabase
        .from('conversations')
        .insert({
          'post_id': postId,  // Link to post if conversation is about an item
        })
        .select('id')
        .single();

    final conversationId = conversation['id'];
    print('✅ Created conversation: $conversationId');

    // STEP 4: Add BOTH users as participants
    // CRITICAL: Both users MUST be added for both to see the messages
    // This is a common bug - forgetting to add both participants
    print('👥 Adding both participants to conversation');
    await supabase.from('conversation_participants').insert([
      {
        'conversation_id': conversationId,
        'user_id': currentUserId,  // Current user
      },
      {
        'conversation_id': conversationId,
        'user_id': otherUserId,  // Other user
      },
    ]);

    print('✅ Both participants added successfully');
    return conversationId;
  }

  /// Send a message
  /// 
  /// This function sends a message in a conversation:
  /// 1. Validates user is logged in
  /// 2. Inserts the message into the messages table
  /// 3. Updates the conversation's last_message_at timestamp
  /// 
  /// Parameters:
  /// - conversationId: ID of the conversation to send message to
  /// - content: The text content of the message
  /// - imageUrl: (Optional) URL of an image attachment
  /// - messageType: Type of message ('text' or 'image')
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
    String messageType = 'text',
  }) async {
    // Validate user is logged in
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    print('📤 Sending message to conversation: $conversationId');
    print('📤 Content: $content');
    print('📤 Sender: $currentUserId');

    // Insert message into messages table
    // The RLS (Row Level Security) policies ensure only participants can send messages
    final result = await supabase.from('messages').insert({
      'conversation_id': conversationId,  // Which conversation this message belongs to
      'sender_id': currentUserId,  // Who sent the message
      'content': content,  // The message text
      'image_url': imageUrl,  // Optional image attachment
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
            // Skip messages deleted for current user
            final deletedFor = List<String>.from(message['deleted_for'] ?? []);
            if (deletedFor.contains(currentUserId)) {
              continue;
            }
            
            final isSentByMe = message['sender_id'] == currentUserId;
            
            // Get sender's display name and avatar from profiles
            String senderName = 'User';
            String? senderAvatar;
            if (!isSentByMe) {
              final profile = await supabase
                  .from('profiles')
                  .select('display_name, email, photo_url')
                  .eq('id', message['sender_id'])
                  .maybeSingle();
              
              senderName = profile?['display_name'] ?? 
                           profile?['email']?.split('@')[0] ?? 
                           'User';
              senderAvatar = profile?['photo_url'];
            } else {
              senderName = 'You';
            }
            
            chatMessages.add(ChatMessage(
              id: message['id'],
              text: message['content'] ?? '',
              timestamp: DateTime.parse(message['created_at']),
              isSentByMe: isSentByMe,
              senderName: senderName,
              senderAvatar: senderAvatar,
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
                .select('display_name, photo_url')
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
              'other_user_avatar': otherUserProfile?['photo_url'],
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

  /// Get unread message count for current user
  Future<int> getUnreadMessageCount() async {
    if (currentUserId == null) return 0;

    try {
      // Get all conversations where user is a participant
      final myConversations = await supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUserId!);

      if (myConversations.isEmpty) return 0;

      final conversationIds = myConversations
          .map((c) => c['conversation_id'] as String)
          .toList();

      // Count unread messages (messages not sent by me and not in my read_by list)
      final messages = await supabase
          .from('messages')
          .select('read_by')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', currentUserId!);

      int unreadCount = 0;
      for (var message in messages) {
        final readBy = List<String>.from(message['read_by'] ?? []);
        if (!readBy.contains(currentUserId)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
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

  /// Delete a message for me only (hides from my view)
  Future<void> deleteMessageForMe(String messageId) async {
    if (currentUserId == null) return;

    try {
      // Get current deleted_for list
      final message = await supabase
          .from('messages')
          .select('deleted_for')
          .eq('id', messageId)
          .maybeSingle();

      if (message != null) {
        final deletedFor = List<String>.from(message['deleted_for'] ?? []);
        if (!deletedFor.contains(currentUserId)) {
          deletedFor.add(currentUserId!);
          await supabase
              .from('messages')
              .update({'deleted_for': deletedFor})
              .eq('id', messageId);
        }
      }
    } catch (e) {
      print('Error deleting message for me: $e');
      throw 'Failed to delete message';
    }
  }

  /// Delete a message for everyone (only sender can do this)
  Future<void> deleteMessageForEveryone(String messageId) async {
    if (currentUserId == null) return;

    try {
      // Verify the message belongs to current user
      final message = await supabase
          .from('messages')
          .select('sender_id')
          .eq('id', messageId)
          .maybeSingle();

      if (message != null && message['sender_id'] == currentUserId) {
        // Delete the message completely
        await supabase
            .from('messages')
            .delete()
            .eq('id', messageId);
      } else {
        throw 'You can only delete your own messages for everyone';
      }
    } catch (e) {
      print('Error deleting message for everyone: $e');
      rethrow;
    }
  }
}
