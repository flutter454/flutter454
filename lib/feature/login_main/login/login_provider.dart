import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginProvider extends ChangeNotifier {
  // -------------------------------
  // Google Sign-In Configuration
  // -------------------------------
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '895215285404-s5lj8gc43cjl51neu23vgekh8cb9jbti.apps.googleusercontent.com',
  );

  // -------------------------------
  // Google → Supabase Login
  // -------------------------------
  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      // FORCE fresh Google token (important)
      await _googleSignIn.signOut();

      debugPrint('🔐 Starting Google Sign-In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign-In cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID Token received from Google');
      }

      // -------------------------------
      // Supabase Authentication
      // -------------------------------
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);

      final user = response.user;

      if (user == null) {
        throw Exception('Supabase user is null');
      }

      debugPrint('✅ Supabase Sign-In Success: ${user.id}');

      // -------------------------------
      // Save User Data Locally
      // -------------------------------
      final userId = user.id;
      final email = user.email ?? googleUser.email;
      final fullName =
          user.userMetadata?['full_name'] ?? googleUser.displayName ?? '';
      final photoUrl =
          user.userMetadata?['avatar_url'] ??
          user.userMetadata?['picture'] ??
          googleUser.photoUrl ??
          '';
      final username = (user.email ?? googleUser.email).split('@')[0];

      await PreferenceService.saveBool('isLoggedIn', true);
      await PreferenceService.saveString('userId', userId);
      await PreferenceService.saveString('email', email);
      await PreferenceService.saveString('fullName', fullName);
      await PreferenceService.saveString('photoUrl', photoUrl);
      await PreferenceService.saveString('username', username);

      notifyListeners();

      return {
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'photoUrl': photoUrl,
        'username': username,
      };
    } catch (e) {
      debugPrint('🚨 CRITICAL: Sign-In Error: $e');
      return null;
    }
  }

  // -------------------------------
  // Logout
  // -------------------------------
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    await _googleSignIn.signOut();

    await PreferenceService.clear();

    notifyListeners();
  }
}
