// storage_service.dart
// Storage service managing Firebase Storage upload tasks for media files.

import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  // Singleton instance
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  /// Uploads an [XFile] to Firebase Storage under 'trip_images/{tripId}/{timestamp}.jpg'.
  /// Returns the accessible public download URL. If cloud storage upload fails or is blocked by CORS/rules,
  /// falls back gracefully to a Base64 data URL so memories are never lost.
  Future<String> uploadTripImage(String tripId, XFile imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'mem_$timestamp.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('trip_images/$tripId/$filename');

    try {
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask.timeout(const Duration(seconds: 3));
        return await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 3));
      } else {
        final file = File(imageFile.path);
        final uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask.timeout(const Duration(seconds: 5));
        return await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('Firebase Storage upload notice ($e). Utilizing data URL fallback.');
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}

