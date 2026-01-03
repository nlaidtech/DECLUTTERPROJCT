import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../main.dart';

/// Compress image in separate isolate (doesn't block UI)
/// 
/// This function runs in a separate thread (isolate) to avoid freezing the UI
/// while compressing large images.
/// 
/// Process:
/// 1. Decodes the image bytes into an image object
/// 2. Resizes if width > 600px (keeps aspect ratio)
/// 3. Compresses to JPEG with 60% quality
/// 4. Returns compressed bytes
/// 
/// Why this matters: Large images (2-3MB) can freeze the app for seconds
/// Running in isolate keeps UI smooth during compression
Uint8List _compressImageIsolate(Uint8List imageBytes) {
  try {
    // Decode the image from bytes
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Resize if too wide (600px is good for mobile screens)
    // This dramatically reduces file size for photos from cameras
    final resized = image.width > 600
        ? img.copyResize(image, width: 600)
        : image;

    // Compress to JPEG with 60% quality
    // 60% is a sweet spot: good quality, much smaller size
    final compressed = img.encodeJpg(resized, quality: 60);

    print(
      'Compressed: ${(imageBytes.length / 1024).toStringAsFixed(0)}KB -> ${(compressed.length / 1024).toStringAsFixed(0)}KB',
    );
    return Uint8List.fromList(compressed);
  } catch (e) {
    print('Error compressing: $e');
    return imageBytes; // Return original if compression fails
  }
}

/// Supabase Storage Service
/// Handles all file uploads to Supabase Storage
class StorageService {
  // Get current user ID
  String? get currentUserId => supabase.auth.currentUser?.id;

  /// Upload a post image to Supabase Storage
  /// 
  /// This function handles the complete image upload process:
  /// 1. Validates user is logged in
  /// 2. Gets image bytes (different methods for web vs mobile)
  /// 3. Compresses the image to reduce file size and upload time
  /// 4. Uploads to Supabase Storage bucket 'post-images'
  /// 5. Returns the public URL where the image can be accessed
  /// 
  /// Why compression: Reduces storage costs and makes app faster
  /// - Original photos from phone cameras can be 2-5MB
  /// - After compression: 100-300KB
  /// - Faster uploads, less mobile data usage
  /// 
  /// Parameters:
  /// - imageFile: The selected image file from file picker
  /// - fileName: Unique name for the file (usually includes timestamp)
  /// 
  /// Returns: Public URL of the uploaded image
  Future<String> uploadPostImage(
    PlatformFile imageFile,
    String fileName,
  ) async {
    // Step 1: Ensure user is authenticated
    // Storage operations require authentication
    await supabase.auth.refreshSession();
    
    if (currentUserId == null) {
      print('ERROR: User not logged in after session refresh');
      print('Current session: ${supabase.auth.currentSession}');
      throw Exception('User not logged in');
    }

    try {
      // Step 2: Create storage path
      // Format: posts/{userId}/{fileName}.jpg
      // This organizes files by user for easy cleanup later
      final path = 'posts/$currentUserId/$fileName.jpg';

      Uint8List imageBytes;

      // Step 3: Get image bytes based on platform
      // Web: uses bytes directly from memory
      // Mobile/Desktop: reads from file path
      if (kIsWeb) {
        if (imageFile.bytes == null) {
          throw Exception('Image bytes are null');
        }
        imageBytes = imageFile.bytes!;
      } else {
        if (imageFile.path == null) {
          throw Exception('Image path is null');
        }
        // Read file from disk
        imageBytes = await File(imageFile.path!).readAsBytes();
      }

      // Step 4: Compress image in background thread
      // Web doesn't support isolates, so compression runs on main thread
      // Mobile/Desktop: runs in separate isolate to keep UI smooth
      final compressedBytes = kIsWeb
          ? _compressImageIsolate(imageBytes) // Web: direct call
          : await compute(_compressImageIsolate, imageBytes); // Mobile: isolate

      // Step 5: Upload to Supabase Storage
      // - Bucket: 'post-images' (must exist in Supabase dashboard)
      // - upsert: true allows overwriting if file exists
      await supabase.storage.from('post-images').uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,  // Allow overwriting existing files
            ),
          );

      // Step 6: Get public URL
      // This URL can be accessed by anyone without authentication
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
