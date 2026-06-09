import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class AvatarImageHelper {
  static String? resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('assets/')) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final baseHost = Uri.parse(ApiConstants.assetBaseUrl).host;
      return path.replaceAll('localhost', baseHost);
    }
    return '${ApiConstants.assetBaseUrl}/storage/$path';
  }

  static ImageProvider? provider(String? path) {
    final url = resolveUrl(path);
    if (url != null) {
      return NetworkImage(url);
    }
    return null;
  }

  static Widget circleAvatar({
    required String? path,
    double radius = 20,
    Color? backgroundColor,
  }) {
    final hasImage = resolveUrl(path) != null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasImage ? provider(path) : null,
      onBackgroundImageError: hasImage ? (_, _) {} : null,
      child: !hasImage
          ? Icon(Icons.person, size: radius, color: Colors.white70)
          : null,
    );
  }
}
