import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteProvider extends ChangeNotifier {
  bool _isLiked = false;
  bool get isLiked => _isLiked;

  final List<String> _comments = [];
  List<String> get comments => _comments;

  String? _currentNoteId;

  // Load likes and comments for a specific note (user_id of the note)
  Future<void> loadReactions(String noteId) async {
    _currentNoteId = noteId;
    _comments.clear();
    _isLiked = false;
    // Don't notify yet to avoid flickering empty state if possible, or do notify to clear old data
    notifyListeners();

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    try {
      // Fetch comments
      final commentsResponse = await supabase
          .from('note_reactions')
          .select('comment_text')
          .eq('note_id', noteId)
          .eq('type', 'comment')
          .order('created_at', ascending: true);

      final List<dynamic> data = commentsResponse as List<dynamic>;
      _comments.addAll(data.map((e) => e['comment_text'] as String));

      // Check if liked by CURRENT USER
      if (userId != null) {
        final likeResponse = await supabase
            .from('note_reactions')
            .select()
            .eq('note_id', noteId)
            .eq('user_id', userId)
            .eq('type', 'like')
            .maybeSingle();

        _isLiked = likeResponse != null;
      }
    } catch (e) {
      debugPrint('Error loading reactions: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleLike() async {
    if (_currentNoteId == null) return;
    final noteId = _currentNoteId!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Optimistic Update
    _isLiked = !_isLiked;
    notifyListeners();

    try {
      if (!_isLiked) {
        // Was liked, now unliked -> Delete
        // Note: _isLiked was flipped above, so if it is NOW false, we delete.
        await supabase
            .from('note_reactions')
            .delete()
            .eq('note_id', noteId)
            .eq('user_id', userId)
            .eq('type', 'like');
      } else {
        // Was unliked, now liked -> Insert
        await supabase.from('note_reactions').insert({
          'note_id': noteId,
          'user_id': userId,
          'type': 'like',
        });
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
      // Revert on error
      _isLiked = !_isLiked;
      notifyListeners();
    }
  }

  Future<void> addComment(String comment) async {
    if (_currentNoteId == null || comment.isEmpty) return;
    final noteId = _currentNoteId!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Optimistic Update
    _comments.add(comment);
    notifyListeners();

    try {
      await supabase.from('note_reactions').insert({
        'note_id': noteId,
        'user_id': userId,
        'type': 'comment',
        'comment_text': comment,
      });
    } catch (e) {
      debugPrint("Error adding comment: $e");
      // Revert
      _comments.removeLast();
      notifyListeners();
    }
  }
}
