// storage_service.dart
// Storage service managing Firebase Storage upload tasks for media files.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  // Singleton instance
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  /// Uploads an [XFile] to Firebase Storage under 'trip_images/{tripId}/{timestamp}.jpg'.
  /// Returns the accessible public download URL.
  Future<String> uploadTripImage(String tripId, XFile imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'mem_$timestamp.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('trip_images/$tripId/$filename');

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      final file = File(imageFile.path);
      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    }
  }
}
