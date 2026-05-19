import 'dart:typed_data';

import 'package:flutter_portfolio/view/customer_service/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageVideoEntry {
  const StorageVideoEntry({
    required this.publicUrl,
    required this.uploaderName,
  });

  final String publicUrl;
  final String uploaderName;
}

class StorageService {
  SupabaseClient? get _supabase {
    if (!isSupabaseConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => _supabase?.auth.currentUser?.id;

  String? get currentUserEmail => _supabase?.auth.currentUser?.email;

  bool isCurrentUserOwner({
    required String ownerUserId,
    required String ownerEmail,
  }) {
    final uid = currentUserId;
    final email = currentUserEmail?.toLowerCase();

    final byId = ownerUserId.isNotEmpty && uid != null && uid == ownerUserId;
    final byEmail =
        ownerEmail.isNotEmpty && email != null && email == ownerEmail.toLowerCase();

    return byId || byEmail;
  }

  Future<List<String>> listBucketUrls(
      {required String bucketName,
      String path = '',
      int limit = 100,
      int offset = 0}) async {
    try {
      final supabase = _supabase;
      if (supabase == null) return [];
      // List files in the bucket
      final response = await supabase.storage
          .from(bucketName)
          .list(
            path: path,
            searchOptions: SearchOptions(limit: limit, offset: offset),
          );

      // Transform file list to public URLs
      final urls = response.map((file) {
        return supabase.storage.from(bucketName).getPublicUrl(file.name);
      }).toList();

      return urls;
    } on StorageException catch (e) {
      print('Error retrieving storage URLs: ${e.message}');
      return [];
    }
  }

  Future<List<StorageVideoEntry>> listBucketVideoEntries({
    required String bucketName,
    String path = '',
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final supabase = _supabase;
      if (supabase == null) return [];

      final response = await supabase.storage.from(bucketName).list(
            path: path,
            searchOptions: SearchOptions(limit: limit, offset: offset),
          );

      return response
          .where((file) => file.name.contains('.'))
          .map((file) {
            final uploader = _extractUploaderName(file.name);
            return StorageVideoEntry(
              publicUrl: supabase.storage.from(bucketName).getPublicUrl(file.name),
              uploaderName: uploader,
            );
          })
          .toList();
    } on StorageException catch (e) {
      print('Error retrieving storage entries: ${e.message}');
      return [];
    }
  }

  Future<String> uploadVideoBytes({
    required String bucketName,
    required Uint8List bytes,
    required String originalFileName,
    required String uploaderName,
    required String uploaderUserId,
    String path = '',
  }) async {
    final supabase = _supabase;
    if (supabase == null) {
      throw StateError('Supabase is not initialized.');
    }

    final ext = _fileExtension(originalFileName);
    final encodedUploader = Uri.encodeComponent(uploaderName.trim());
    final encodedUid = Uri.encodeComponent(uploaderUserId.trim());
    final fileName =
        '${encodedUploader}__${encodedUid}__video_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'mp4' : ext}';
    final targetPath = path.isEmpty ? fileName : '$path/$fileName';

    await supabase.storage.from(bucketName).uploadBinary(
          targetPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _videoContentType(ext),
          ),
        );

    return supabase.storage.from(bucketName).getPublicUrl(targetPath);
  }

  String _extractUploaderName(String fileName) {
    final parts = fileName.split('__');
    if (parts.isEmpty) return 'Người dùng ẩn danh';
    try {
      final decoded = Uri.decodeComponent(parts.first);
      return decoded.isEmpty ? 'Người dùng ẩn danh' : decoded;
    } catch (_) {
      return 'Người dùng ẩn danh';
    }
  }

  String _fileExtension(String name) {
    final idx = name.lastIndexOf('.');
    if (idx == -1 || idx == name.length - 1) return '';
    return name.substring(idx + 1).toLowerCase();
  }

  String _videoContentType(String ext) {
    switch (ext) {
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'm4v':
        return 'video/x-m4v';
      default:
        return 'video/mp4';
    }
  }

  // Optional: Get signed URLs for private files
  Future<List<String>> listSignedUrls(
      {required String bucketName,
        String path = '',
        int limit = 100,
        Duration expiresIn = const Duration(hours: 1)}) async {
    try {
      final supabase = _supabase;
      if (supabase == null) return [];

      final response = await supabase.storage
          .from(bucketName)
          .list(path: path, searchOptions: SearchOptions(limit: limit));

      final signedUrls = await Future.wait(response.map((file) async {
        return await supabase.storage
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
