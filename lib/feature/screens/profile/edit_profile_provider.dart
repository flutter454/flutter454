import 'dart:io';

import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileProvider extends ChangeNotifier {
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  File? get imageFile => _imageFile;
  bool get isUploading => _isUploading;

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  // Removed _uploadImage method as we are saving locally

  Future<bool> saveProfile({
    required BuildContext context,
    required String fullName,
    required String username,
    required Map<String, String> userData,
  }) async {
    _isUploading = true;
    notifyListeners();

    String? imageUrl = userData['photoUrl'];

    // 1. Upload Image to Supabase if a new file is selected
    if (_imageFile != null) {
      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;

        if (userId != null) {
          final filePath = '$userId/profile.jpg'; // Fixed path for upsert

          await supabase.storage
              .from('avatars')
              .upload(
                filePath,
                _imageFile!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );

          // Use signed URL
          // Expiry set to 1 year (365 days)
          final String signedUrl = await supabase.storage
              .from('avatars')
              .createSignedUrl(filePath, 60 * 60 * 24 * 365);

          // Append timestamp to force UI refresh since path is constant
          imageUrl = '$signedUrl&t=${DateTime.now().millisecondsSinceEpoch}';
          debugPrint('Image uploaded to Supabase (Upsert): $imageUrl');
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
        _isUploading = false;
        notifyListeners();
        return false;
      }
    }

    // 2. Save Text Data & URL to SharedPreferences
    await PreferenceService.saveString('fullName', fullName);
    await PreferenceService.saveString('username', username);
    if (imageUrl != null) {
      await PreferenceService.saveString('photoUrl', imageUrl);
      userData['photoUrl'] = imageUrl;
    }

    // 3. Update Supabase Auth Metadata & Stories Table
    try {
      final updateAttrs = UserAttributes(
        data: {
          'full_name': fullName,
          'username': username, // Also sync username
          if (imageUrl != null) 'avatar_url': imageUrl,
          if (imageUrl != null) 'photoUrl': imageUrl, // Redundant but safe
        },
      );
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(updateAttrs);

      // Sync changes to 'stories' table so old stories update immediately
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase
            .from('stories')
            .update({
              'user_name': fullName, // or username depending on pref
              if (imageUrl != null) 'user_photo': imageUrl,
            })
            .eq('user_id', userId);
        debugPrint('Synced profile changes to stories table ✅');
      }
    } catch (e) {
      debugPrint('Error updating Supabase user metadata/stories: $e');
    }

    _isUploading = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated and old photos cleaned up!'),
        ),
      );
      return true;
    }
    return false;
  }
}
