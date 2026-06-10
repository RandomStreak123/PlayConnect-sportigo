import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/match_details_screen.dart';

class DeepLinkService {
  final GlobalKey<NavigatorState> navigatorKey;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService({required this.navigatorKey});

  void initialize() {
    // Handle cold start deep links (initial link when app starts)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle runtime deep links (when app is in background or foreground)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    
    // Parse match ID from the URI.
    // Scheme could be sportigo://matches/<id> or https://sportigo.com/matches/<id>
    String? matchId;
    
    if (uri.scheme == 'sportigo' && uri.host == 'matches') {
      // e.g. sportigo://matches/12
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        matchId = segments.first;
      }
    } else if (uri.path.startsWith('/matches/')) {
      // e.g. https://sportigo.com/matches/12
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        matchId = segments[1];
      }
    }

    if (matchId != null) {
      debugPrint('Parsed Match ID from deep link: $matchId');
      _navigateToMatchDetails(matchId);
    }
  }

  void _navigateToMatchDetails(String matchId) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      // If navigator context is not ready, retry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () => _navigateToMatchDetails(matchId));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(matchId: matchId),
      ),
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
