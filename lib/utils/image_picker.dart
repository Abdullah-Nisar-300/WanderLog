// image_picker.dart
// Unified entry point for picking images using conditional imports.

import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart' as impl;

Future<String?> pickUserImage() {
  return impl.pickImage();
}
