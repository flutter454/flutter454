import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  // List to store fetched songs
  List<Map<String, String>> _songs = [];
  bool _isLoading = false;

  String? _playingId; // Track by ID

  bool get isLoading => _isLoading;
  String? get playingId => _playingId;
  List<Map<String, String>> get songs => _songs;

  MusicProvider() {
    // Fetch songs on init
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    _isLoading = true;
    notifyListeners();

    // Queries for our heroes
    final queries = [
      'Prabhas Telugu',
      'Mahesh Babu Telugu',
      'Allu Arjun Telugu',
      'Jr NTR Telugu',
      'Ram Charan Telugu',
      'Chiranjeevi Telugu',
    ];

    final Set<String> trackIds = {};
    final List<Map<String, String>> fetchedSongs = [];

    try {
      // Fetch concurrently for better performance
      await Future.wait(
        queries.map((query) async {
          final url = Uri.parse(
            'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=15&country=IN',
          );

          try {
            final response = await http.get(url);
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final results = data['results'] as List;

              for (var item in results) {
                // Use trackId to avoid duplicates across queries
                final id = item['trackId'].toString();
                if (!trackIds.contains(id)) {
                  trackIds.add(id);
                  fetchedSongs.add({
                    'id': id, // Store ID
                    'name': item['trackName'] ?? 'Unknown',
                    'artist': item['artistName'] ?? 'Unknown',
                    'url':
                        item['previewUrl'] ??
                        '', // Valid 30s accessible preview
                    'cover':
                        item['artworkUrl100']?.replaceAll(
                          '100x100',
                          '600x600',
                        ) ??
                        '', // High res cover
                  });
                }
              }
            }
          } catch (e) {
            debugPrint('Error fetching for $query: $e');
          }
        }),
      );

      fetchedSongs.shuffle();
      _songs = fetchedSongs;
    } catch (e) {
      debugPrint('Global fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePreview(String id, String url) async {
    if (url.isEmpty) return;

    if (_playingId == id) {
      _playingId = null;
      notifyListeners();
      await _player.stop();
    } else {
      // Update UI IMMEDIATELY
      _playingId = id;
      notifyListeners();

      try {
        await _player.stop();
        await _player.setUrl(url);
        await _player.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
        // Revert UI if it failed
        if (_playingId == id) {
          _playingId = null;
          notifyListeners();
        }
      }
    }
  }

  void stopPreview() {
    _player.stop();
    _playingId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
