import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../main.dart';

/// Compress image in separate isolate (doesn't block UI)
Uint8List _compressImageIsolate(Uint8List imageBytes) {
  try {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Very aggressive: max 600px width
    final resized = image.width > 600
        ? img.copyResize(image, width: 600)
        : image;

    // Lower quality: 60%
    final compressed = img.encodeJpg(resized, quality: 60);

    print(
      'Compressed: ${(imageBytes.length / 1024).toStringAsFixed(0)}KB -> ${(compressed.length / 1024).toStringAsFixed(0)}KB',
    );
    return Uint8List.fromList(compressed);
  } catch (e) {
    print('Error compressing: $e');
    return imageBytes;
  }
}

/// Supabase Storage Service
/// Handles all file uploads to Supabase Storage
class StorageService {
  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  /// Upload a post image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadPostImage(
    PlatformFile imageFile,
    String fileName,
  ) async {
    // Refresh session to make sure user is logged in
    await supabase.auth.refreshSession();
    
    if (currentUserId == null) {
      print('ERROR: User not logged in after session refresh');
      print('Current session: ${supabase.auth.currentSession}');
      throw Exception('User not logged in');
    }

    try {
      // Create a path for the file
      final path = 'posts/$currentUserId/$fileName.jpg';

      Uint8List imageBytes;

      // Get image bytes based on platform
      if (kIsWeb) {
        if (imageFile.bytes == null) {
          throw Exception('Image bytes are null');
        }
        imageBytes = imageFile.bytes!;
      } else {
        if (imageFile.path == null) {
          throw Exception('Image path is null');
        }
        imageBytes = await File(imageFile.path!).readAsBytes();
      }

      // Compress image in background isolate (doesn't freeze UI)
      final compressedBytes = kIsWeb
          ? _compressImageIsolate(imageBytes) // Web doesn't support isolates
          : await compute(_compressImageIsolate, imageBytes);

      // Upload to Supabase Storage
      await supabase.storage.from('post-images').uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get the public URL
      final publicUrl = supabase.storage.from('post-images').getPublicUrl(path);

      print('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a profile picture to Supabase Storage
  Future<String> uploadProfilePicture(PlatformFile imageFile) async {
    // Refresh session to make sure user is logged in
    await supabase.auth.refreshSession();
    
    if (currentUserId == null) {
      print('ERROR: User not logged in after session refresh');
      print('Current session: ${supabase.auth.currentSession}');
      throw Exception('User not logged in');
    }

    try {
      final path = 'profiles/$currentUserId/profile.jpg';

      Uint8List imageBytes;

      if (kIsWeb) {
        if (imageFile.bytes == null) {
          throw Exception('Image bytes are null');
        }
        imageBytes = imageFile.bytes!;
      } else {
        if (imageFile.path == null) {
          throw Exception('Image path is null');
        }
        imageBytes = await File(imageFile.path!).readAsBytes();
      }

      // Compress image in background isolate (doesn't freeze UI)
      final compressedBytes = kIsWeb
          ? _compressImageIsolate(imageBytes)
          : await compute(_compressImageIsolate, imageBytes);

      // Use post-images bucket (same as posts) since avatars bucket may not exist
      await supabase.storage.from('post-images').uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage.from('post-images').getPublicUrl(path);

      print('Profile picture uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Delete an image from Supabase Storage
  Future<void> deleteImage(String imageUrl, String bucket) async {
    try {
      // Extract path from public URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;
      
      await supabase.storage.from(bucket).remove([path]);
      print('Image deleted successfully: $imageUrl');
    } catch (e) {
      print('Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Delete all images for a post
  Future<void> deletePostImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await deleteImage(url, 'post-images');
      } catch (e) {
        print('Error deleting image $url: $e');
        // Continue deleting other images even if one fails
      }
    }
  }
}
