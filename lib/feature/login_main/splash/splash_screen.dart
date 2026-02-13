// ignore_for_file: deprecated_member_use

import 'package:chatloop/feature/login_main/dashboard/dashboard.dart';
import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:chatloop/feature/login_main/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait for 3 seconds for the splash effect
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    debugPrint('SplashScreen: Checking login status... result: $isLoggedIn');

    if (!mounted) return;

    if (isLoggedIn) {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentSession == null) {
        debugPrint(
          'Supabase session missing, attempting silent Google sign-in...',
        );
        try {
          final googleSignIn = GoogleSignIn(
            serverClientId:
                '895215285404-s5lj8gc43cjl51neu23vgekh8cb9jbti.apps.googleusercontent.com',
          );
          final googleUser = await googleSignIn.signInSilently();
          if (googleUser != null) {
            final googleAuth = await googleUser.authentication;
            if (googleAuth.idToken != null && googleAuth.accessToken != null) {
              await supabase.auth.signInWithIdToken(
                provider: OAuthProvider.google,
                idToken: googleAuth.idToken!,
                accessToken: googleAuth.accessToken,
              );
              debugPrint('Supabase silent sign-in successful');
            }
          }
        } catch (e) {
          debugPrint('Error restoring Supabase session: $e');
        }
      }

      // Sync latest profile from Supabase Auth Metadata
      final user = supabase.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata;
        if (metadata != null) {
          debugPrint('Syncing profile from Supabase metadata...');

          String? remotePhotoUrl =
              metadata['avatar_url'] ?? metadata['photoUrl'];

          // Sanitize URL if it contains extra data (comma separator)
          if (remotePhotoUrl != null && remotePhotoUrl.contains(',')) {
            remotePhotoUrl = remotePhotoUrl.split(',').first.trim();
          }

          final String? remoteFullName =
              metadata['full_name'] ?? metadata['fullName'];
          final String? remoteUsername = metadata['username'];

          if (remotePhotoUrl != null && remotePhotoUrl.isNotEmpty) {
            await prefs.setString('photoUrl', remotePhotoUrl);
          }
          if (remoteFullName != null && remoteFullName.isNotEmpty) {
            await prefs.setString('fullName', remoteFullName);
          }
          if (remoteUsername != null && remoteUsername.isNotEmpty) {
            await prefs.setString('username', remoteUsername);
          }
        }
      }

      // Load stored data to pass to UserDetails
      final Map<String, String> userData = {
        'fullName': prefs.getString('fullName') ?? '',
        'username': prefs.getString('username') ?? '',
        'email': prefs.getString('email') ?? '',
        'photoUrl': prefs.getString('photoUrl') ?? '',
        'dob': prefs.getString('dob') ?? '',
        'gender': prefs.getString('gender') ?? '',
        'instagram': prefs.getString('instagram') ?? '',
        'youtube': prefs.getString('youtube') ?? '',
      };

      // Restore last visited screen index
      final int savedIndex = prefs.getInt('dashboard_index') ?? 0;
      if (mounted) {
        context.read<DashboardProvider>().setSelectedIndex(savedIndex);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Dashboard(userData: userData)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8338EC), // Vibrant Purple
              Color(0xFFFF006E), // Vibrant Pink
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart Logo for Love Line
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF006E),
                    size: 60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // App Name - Love Line with stylistic font
            // const Text(
            //   "Love Line",
            //   style: TextStyle(
            //     fontSize: 56,
            //     fontWeight: FontWeight.w800,
            //     color: Colors.white,
            //     letterSpacing: -1.0,
            //     shadows: [
            //       Shadow(
            //         color: Colors.black26,
            //         offset: Offset(0, 4),
            //         blurRadius: 10,
            //       ),
            //     ],
            //   ),
            // ),
            //screen
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "Find your perfect loop",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
