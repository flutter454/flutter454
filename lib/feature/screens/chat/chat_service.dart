import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Get or Create Chat (Prevents duplicates)
  // Checks for existing chat between current user and friend.
  // We enforce an ordering of IDs to ensure uniqueness: a single chat for (A, B) regardless of who initiated.
  // Alternatively, we check both (A,B) and (B,A) existence.
  Future<String> getOrCreateChat(String currentUserId, String friendId) async {
    // Determine user1 and user2 based on sorting to ensure consistency if we used a unique constraint (u1 < u2).
    // However, the prompt asks to check both directions.
    // Let's try to find an existing chat first.

    final response = await _supabase
        .from('chats')
        .select()
        .or(
          'and(user1_id.eq.$currentUserId,user2_id.eq.$friendId),and(user1_id.eq.$friendId,user2_id.eq.$currentUserId)',
        )
        .maybeSingle();

    if (response != null) {
      return response['id'] as String;
    }

    // No chat exists, create a new one.
    // We can just insert. Trigger or RLS will handle the rest.
    final newChat = await _supabase
        .from('chats')
        .insert({
          'user1_id': currentUserId,
          'user2_id': friendId,
          // 'created_at': now(), // Default
          // 'last_message_at': now(), // Default from trigger/table definition
        })
        .select()
        .single();

    return newChat['id'] as String;
  }

  // 2. Send Message
  Future<void> sendMessage(
    String chatId,
    String currentUserId,
    String text,
  ) async {
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': currentUserId,
      'text': text,
      // 'created_at' is default
      // 'is_seen' is false default
    });
  }

  // 3. Stream Messages (Realtime)
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    // We stream all messages for the chat, ordered by creation time.
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  // 4. Mark Messages as Seen
  Future<void> markMessagesAsSeen(String chatId, String currentUserId) async {
    // Update all messages in this chat where the sender is NOT the current user
    // and is_seen is false.
    await _supabase
        .from('messages')
        .update({'is_seen': true})
        .eq('chat_id', chatId)
        .neq('sender_id', currentUserId)
        .eq('is_seen', false);
  }

  // 5. Get My Chats (List with Last Message)
  Future<List<Map<String, dynamic>>> getMyChats(String currentUserId) async {
    try {
      // 1. Fetch Chats
      final response = await _supabase
          .from('chats')
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('last_message_at', ascending: false);

      final List<Map<String, dynamic>> chats = List<Map<String, dynamic>>.from(
        response,
      );

      if (chats.isEmpty) return [];

      // 2. Collect unique friend IDs
      final Set<String> friendIds = {};
      for (var chat in chats) {
        String u1 = chat['user1_id'];
        String u2 = chat['user2_id'];
        if (u1 != currentUserId) friendIds.add(u1);
        if (u2 != currentUserId) friendIds.add(u2);
      }

      if (friendIds.isEmpty) return chats;

      // 3. Fetch Profiles for friends
      final profilesResponse = await _supabase
          .from(
            'profiles',
          ) // Assuming 'profiles' table exists and matches auth.uid
          .select()
          .filter('id', 'in', '(${friendIds.join(',')})');

      final Map<String, Map<String, dynamic>> profilesMap = {
        for (var p in profilesResponse) p['id'] as String: p,
      };

      // 4. Merge Data & Fetch Last Message
      for (var chat in chats) {
        String u1 = chat['user1_id'];
        String u2 = chat['user2_id'];
        String friendId = (u1 == currentUserId) ? u2 : u1;

        chat['friend_profile'] = profilesMap[friendId];

        // Fetch last message content
        // Optimization: create database index on (chat_id, created_at)
        final msgResponse = await _supabase
            .from('messages')
            .select('text, created_at, is_seen, sender_id')
            .eq('chat_id', chat['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (msgResponse != null) {
          chat['last_message'] = msgResponse;
        }
      }
      return chats;
    } catch (e) {
      debugPrint('Error getting chats: $e');
      return [];
    }
  }

  // 6. Delete Message
  Future<void> removeMessage(String messageId) async {
    debugPrint('Deleting message: $messageId');
    await _supabase.from('messages').delete().eq('id', messageId);
  }
}
