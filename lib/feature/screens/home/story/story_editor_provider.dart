import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryEditorProvider extends ChangeNotifier {
  // Video State
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  // Overlay State
  Offset _overlayOffset = const Offset(100, 300);
  String _activeOverlayText = '';
  bool _showOverlayInput = false;

  // Music State
  String? _selectedMusicName;
  String? _selectedMusicUrl;
  String? _selectedMusicCover;
  bool _isMusicPlaying = false;

  // Getters
  VideoPlayerController? get videoController => _videoController;
  bool get isInitialized => _isInitialized;
  Offset get overlayOffset => _overlayOffset;
  String get activeOverlayText => _activeOverlayText;
  bool get showOverlayInput => _showOverlayInput;
  String? get selectedMusicName => _selectedMusicName;
  String? get selectedMusicUrl => _selectedMusicUrl;
  String? get selectedMusicCover => _selectedMusicCover;
  bool get isMusicPlaying => _isMusicPlaying;

  Future<void> initializeVideo(File file) async {
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    _isInitialized = true;
    _videoController!.play();
    _videoController!.setLooping(true);
    notifyListeners();
  }

  void updateOverlayOffset(Offset delta) {
    _overlayOffset += delta;
    notifyListeners();
  }

  void setActiveOverlayText(String text) {
    _activeOverlayText = text;
    notifyListeners();
  }

  void setShowOverlayInput(bool show) {
    _showOverlayInput = show;
    notifyListeners();
  }

  void setMusic(String? name, String? url, String? cover) {
    _selectedMusicName = name;
    _selectedMusicUrl = url;
    _selectedMusicCover = cover;
    _isMusicPlaying = name != null;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
