import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'music_provider.dart';

class MusicSelectionSheet extends StatelessWidget {
  final Function(String songName, String url, String coverUrl) onSongSelected;

  const MusicSelectionSheet({super.key, required this.onSongSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark Insta-like background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  'Search music',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, thickness: 0.5),

          // List
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                if (musicProvider.isLoading && musicProvider.songs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: musicProvider.songs.length,
                  itemBuilder: (context, index) {
                    final song = musicProvider.songs[index];
                    final isPlaying = musicProvider.playingId == song['id'];

                    return ListTile(
                      key: ValueKey(
                        song['id'],
                      ), // Unique key for state preservation
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song['cover']!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (isPlaying)
                            Container(
                              color: Colors.black54,
                              child: const Icon(
                                Icons.pause,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        song['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        song['artist']!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: isPlaying
                          ? IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 30,
                              ),
                              onPressed: () {
                                // Stop preview before selecting
                                musicProvider.stopPreview();
                                onSongSelected(
                                  song['name']!,
                                  song['url']!,
                                  song['cover']!,
                                );
                              },
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                              ),
                              onPressed: () => musicProvider.togglePreview(
                                song['id']!,
                                song['url']!,
                              ),
                            ),
                      onTap: () => musicProvider.togglePreview(
                        song['id']!,
                        song['url']!,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
