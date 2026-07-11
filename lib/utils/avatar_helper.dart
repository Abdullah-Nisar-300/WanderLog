// avatar_helper.dart
// Decodes and returns the appropriate ImageProvider for standard URLs or Base64 data strings.

import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider getAvatarProvider(String avatarUrl) {
  if (avatarUrl.startsWith('data:image') || avatarUrl.startsWith('data:')) {
    try {
      final base64Str = avatarUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } catch (e) {
      // Fallback if parsing fails
    }
  }
  
  // Default to standard NetworkImage
  return NetworkImage(avatarUrl);
}
