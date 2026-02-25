import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageUtils {
  /// Returns an appropriate ImageProvider for the given URL.
  /// Handles local file paths (file://), asset paths (assets/), and network URLs.
  static ImageProvider? getImageProvider(
    String? url, {
    int? maxWidth,
    int? maxHeight,
  }) {
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('file://')) {
      final path = url.substring(7);
      return FileImage(File(path));
    } else if (url.startsWith('assets/')) {
      return AssetImage(url);
    } else {
      return CachedNetworkImageProvider(
        url,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
  }

  /// Returns an appropriate Widget for the given URL.
  static Widget getImageWidget(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    if (url == null || url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.grey),
      );
    }

    if (url.startsWith('file://')) {
      final path = url.substring(7);
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
      );
    } else {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.grey),
        ),
      );
    }
  }
}
