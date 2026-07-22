// memory_image_widget.dart
// Custom widget to render memory photos supporting standard HTTP network URLs,
// local asset URLs, and Base64 data URLs gracefully.

import 'dart:convert';
import 'package:flutter/material.dart';

class MemoryImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const MemoryImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.white10,
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 36),
            ),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.white10,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 36),
          ),
        );
      }
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.white10,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.white10,
          child: const Center(
            child: Icon(Icons.photo_rounded, color: Colors.white30, size: 36),
          ),
        );
      },
    );
  }
}
