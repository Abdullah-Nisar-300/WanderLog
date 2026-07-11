// image_picker_web.dart
// Web implementation of the image picker using native HTML FileUploadInputElement.

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImage() async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  
  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as String?);
      });
      reader.onError.listen((e) {
        completer.complete(null);
      });
    } else {
      completer.complete(null);
    }
  });

  // Programmatically trigger click to show browser file picker dialog
  uploadInput.click();
  return completer.future;
}
