import 'dart:io';

import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  final String? coverUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  const BookCover({
    super.key,
    required this.coverUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final isNetworkImage =
        coverUrl!.startsWith("http://") || coverUrl!.startsWith("https://");

    if (isNetworkImage) {
      return Image.network(
        coverUrl!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      // Cleans virtual prefix schemas if stored in DB
      final cleanPath = coverUrl!.startsWith("file://")
          ? coverUrl!.replaceFirst("file://", "")
          : coverUrl!;
      return Image.file(
        File(cleanPath),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      "assets/images/placeholder_book.png",
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
    );
  }
}
