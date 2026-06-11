import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class AvatarImageHelper {
  static String? resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('assets/')) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        final uri = Uri.parse(path);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final baseUri = Uri.parse(ApiConstants.assetBaseUrl);
          return uri.replace(
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          ).toString();
        }
      } catch (_) {
        final baseHost = Uri.parse(ApiConstants.assetBaseUrl).host;
        return path.replaceAll('localhost', baseHost).replaceAll('127.0.0.1', baseHost);
      }
      return path;
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
          child: Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: radius, color: Colors.white70);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
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
      child: Icon(Icons.person, size: radius, color: Colors.white70),
    );
  }
}
