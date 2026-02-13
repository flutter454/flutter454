import 'package:flutter/material.dart';

class HomePageProvider extends ChangeNotifier {
  final List<Map<String, String>> _stories = [
    {'name': 'Sree', 'image': 'https://i.pravatar.cc/150?u=1'},
    {'name': 'Chenna', 'image': 'https://i.pravatar.cc/150?u=2'},
    {'name': 'littel', 'image': 'https://i.pravatar.cc/150?u=3'},
    {'name': 'sreenadh', 'image': 'https://i.pravatar.cc/150?u=4'},
  ];

  final List<Map<String, String>> _posts = [
    {
      'user': 'lil_wyatt838',
      'avatar': 'https://i.pravatar.cc/150?u=5',
      'image': 'https://picsum.photos/id/1011/800/800',
      'caption': 'Spending time with the squad! 📸',
    },
    {
      'user': 'adventure_seeker',
      'avatar': 'https://i.pravatar.cc/150?u=6',
      'image': 'https://picsum.photos/id/1015/800/800',
      'caption': 'The view from up here is incredible. ⛰️',
    },
    {
      'user': 'urban_explorer',
      'avatar': 'https://i.pravatar.cc/150?u=7',
      'image': 'https://picsum.photos/id/1016/800/800',
      'caption': 'City lights and late nights. 🌃',
    },
  ];

  List<Map<String, String>> get stories => _stories;
  List<Map<String, String>> get posts => _posts;
}
