import 'package:flutter/material.dart';

class ActiveUserItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String note;
  final bool isCurrentUser;

  const ActiveUserItem({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.note,
    this.isCurrentUser = false,
    this.onTap,
    this.currentSong,
  });

  final VoidCallback? onTap;
  final Map<String, String>? currentSong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  // Note Bubble
                  if (!isCurrentUser)
                    Positioned(
                      top: -10,
                      left: 0,
                      right: 0,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          note,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  if (isCurrentUser)
                    Positioned(
                      top:
                          -25, // Adjusted to make room for larger bubble if needed
                      left: 0,
                      right: 0,
                      child: Center(child: _buildCurrentUserBubble()),
                    ),
                  if (isCurrentUser)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.add, size: 16, color: Colors.black),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 75,
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.2,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserBubble() {
    return Container(
      width: 80, // Slightly wider for the text
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: currentSong != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note, size: 12, color: Colors.purple),
                Text(
                  "${currentSong!['title']}",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${currentSong!['artist']}",
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Text(
              note.isNotEmpty ? note : 'Add your\nfavorite song?',
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
