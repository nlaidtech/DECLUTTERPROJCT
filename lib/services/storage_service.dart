import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

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

/// Firebase Storage Service
/// Handles all file uploads to Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Upload a post image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadPostImage(
    PlatformFile imageFile,
    String fileName,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Create a reference to the file location
      final ref = _storage.ref().child('posts/$currentUserId/$fileName.jpg');

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

      // Upload compressed image
      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a profile picture to Firebase Storage
  Future<String> uploadProfilePicture(PlatformFile imageFile) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final ref = _storage.ref().child('profiles/$currentUserId/profile.jpg');

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

      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
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
        await deleteImage(url);
      } catch (e) {
        print('Error deleting image $url: $e');
        // Continue deleting other images even if one fails
      }
    }
  }
}
