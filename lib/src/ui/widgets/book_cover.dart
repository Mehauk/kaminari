import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A custom CacheManager dedicated to book covers with a highly persistent lifecycle.
class BookCoverCacheManager {
  static const String key = 'book_covers_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 365 * 100),
      maxNrOfCacheObjects: 0x7fffffffffffffff,
    ),
  );
}

class BookCover extends StatelessWidget {
  final String? coverUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool cacheImage;

  const BookCover({
    super.key,
    required this.coverUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheImage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final isNetworkImage =
        coverUrl!.startsWith("http://") || coverUrl!.startsWith("https://");

    if (isNetworkImage) {
      if (cacheImage) {
        return CachedNetworkImage(
          imageUrl: coverUrl!,
          cacheManager: BookCoverCacheManager.instance,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          placeholder: (_, _) => _buildPlaceholder(),
          errorWidget: (_, _, _) => _buildPlaceholder(),
        );
      } else {
        // Standard, non-cached transient network render for preview screens
        return Image.network(
          coverUrl!,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      }
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
