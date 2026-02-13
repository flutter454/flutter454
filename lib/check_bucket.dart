import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> checkBucket() async {
  try {
    final supabase = Supabase.instance.client;

    // Try to list files in avatars bucket
    final List<FileObject> files = await supabase.storage
        .from('avatars')
        .list();

    print('Files in avatars bucket: ${files.length}');
    for (var file in files) {
      print('- ${file.name}');
    }

    // Check public URL for a non-existent file just to see format
    final url = supabase.storage.from('avatars').getPublicUrl('test.png');
    print('Generated Public URL format: $url');
  } catch (e) {
    print('Error accessing avatars bucket: $e');
  }
}
