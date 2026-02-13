import 'package:flutter/material.dart';

class SingleSongItem extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const SingleSongItem({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(artist),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.purple)
          : null,
    );
  }
}

class SongSelectionScreen extends StatelessWidget {
  final Function(Map<String, String>) onSongSelected;

  SongSelectionScreen({super.key, required this.onSongSelected});

  final List<Map<String, String>> _songs = [
    {
      'title': 'Shape of You',
      'artist': 'Ed Sheeran',
      'image':
          'https://i.scdn.co/image/ab67616d0000b273ba5db46f4b838ef6027e6f96',
    },
    {
      'title': 'Blinding Lights',
      'artist': 'The Weeknd',
      'image':
          'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36',
    },
    {
      'title': 'Stay',
      'artist': 'The Kid LAROI, Justin Bieber',
      'image':
          'https://i.scdn.co/image/ab67616d0000b27341e31d6ea1d493dd77933e2f',
    },
    {
      'title': 'Levitating',
      'artist': 'Dua Lipa',
      'image':
          'https://i.scdn.co/image/ab67616d0000b273bd26ede1ae69327010d49946',
    },
    {
      'title': 'Peaches',
      'artist': 'Justin Bieber',
      'image':
          'https://i.scdn.co/image/ab67616d0000b273e6f407c7f3a0ec98845e4431',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Song"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return SingleSongItem(
            title: song['title']!,
            artist: song['artist']!,
            imageUrl: song['image']!,
            onTap: () {
              onSongSelected(song);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
