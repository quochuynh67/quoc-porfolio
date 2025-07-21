import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<String>> listBucketUrls(
      {required String bucketName, String path = '', int limit = 100}) async {
    try {
      // List files in the bucket
      final response = await _supabase.storage
          .from(bucketName)
          .list(path: path, searchOptions: SearchOptions(limit: limit));

      // Transform file list to public URLs
      final urls = response.map((file) {
        return _supabase.storage.from(bucketName).getPublicUrl(file.name);
      }).toList();

      return urls;
    } on StorageException catch (e) {
      print('Error retrieving storage URLs: ${e.message}');
      return [];
    }
  }

  // Optional: Get signed URLs for private files
  Future<List<String>> listSignedUrls(
      {required String bucketName,
        String path = '',
        int limit = 100,
        Duration expiresIn = const Duration(hours: 1)}) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .list(path: path, searchOptions: SearchOptions(limit: limit));

      final signedUrls = await Future.wait(response.map((file) async {
        return await _supabase.storage
            .from(bucketName)
            .createSignedUrl(file.name, expiresIn.inSeconds);
      }));

      return signedUrls;
    } on StorageException catch (e) {
      print('Error retrieving signed URLs: ${e.message}');
      return [];
    }
  }
}
