import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constants.dart';

class AvatarImageHelper {
  static String? resolveUrl(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    if (path.startsWith('assets/')) {
      return null;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      String resolved = path;
      try {
        final uri = Uri.parse(path);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final baseUri = Uri.parse(ApiConstants.assetBaseUrl);
          resolved = uri.replace(
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          ).toString();
        }
      } catch (_) {
        final baseHost = Uri.parse(ApiConstants.assetBaseUrl).host;
        resolved = path.replaceAll('localhost', baseHost).replaceAll('127.0.0.1', baseHost);
      }
      return resolved;
    }
    return '${ApiConstants.assetBaseUrl}/storage/$path';
  }

  static ImageProvider? provider(String? path) {
    final url = resolveUrl(path);
    if (url != null) {
      return CachedNetworkImageProvider(url);
    }
    return null;
  }

  static Widget circleAvatar({
    required String? path,
    double radius = 20,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final url = resolveUrl(path);
    if (url != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.grey.shade300,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) {
              return Icon(Icons.person, size: radius, color: foregroundColor ?? Colors.white70);
            },
            placeholder: (context, url) {
              return Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(Icons.person, size: radius, color: foregroundColor ?? Colors.white70),
    );
  }
}
