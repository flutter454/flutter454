// ignore_for_file: deprecated_member_use

import 'package:chatloop/feature/login_main/dashboard/dashboard.dart';
import 'package:chatloop/feature/screens/home/story/story_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page_widgets.dart';
import 'login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && mounted) {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(userData: userData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Consumer<LoginProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            primary: false,
            backgroundColor: const Color(0xFFFFEBF2),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome to ChatLoop',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join the Love Line community',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8E8E8E),
                        ),
                      ),
                      const SizedBox(height: 48),

                      ProfileTextField(
                        controller: phoneController,
                        hintText: 'Enter Phone Number',
                        prefixIcon: Icons.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      LoginButton(
                        text: 'Sign In with Phone',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Implement Phone Login logic if needed
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone login initiated...'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LoginButton(
                        text: 'Sign In with Google',
                        color: Colors.white,
                        textColor: Colors.black87,
                        icon: Image.network(
                          'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () async {
                          final userData = await provider.signInWithGoogle();
                          if (userData != null && mounted) {
                            await context.read<StoryProvider>().refresh();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Dashboard(userData: userData),
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sign-In failed. Please check your internet or Firebase console settings (SHA-1).',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
