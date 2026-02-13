// ignore_for_file: avoid_print

import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Match the Web Client ID used in LoginProvider
    serverClientId:
        '895215285404-s5lj8gc43cjl51neu23vgekh8cb9jbti.apps.googleusercontent.com',
  );

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();

      await PreferenceService.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Even if one fails, clear prefs to force login screen
      await PreferenceService.clear();
      notifyListeners();
    }
  }
}
