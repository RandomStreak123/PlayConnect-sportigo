import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../core/router/app_router.dart';
import '../core/di/service_locator.dart';
import '../data/repositories/auth_repository.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService();

  static Uri? pendingDeepLink;

  void initialize() {
    // Handle cold start deep links (initial link when app starts).
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        if (uri.scheme == 'sportigo' && uri.host == 'reset-password') {
          // For reset-password links at cold start, we must NOT navigate
          // immediately because the auth BlocListener's listenWhen condition
          // does NOT fire for the initial unknown→unauthenticated transition,
          // meaning any early navigation gets overridden by the '/' route's
          // StreamBuilder showing LoginScreen.
          //
          // Solution: subscribe to authRepo.status, which is a fresh async*
          // generator that yields the settled status (authenticated or
          // unauthenticated) after reading SharedPreferences. We navigate
          // on the first emission — guaranteed to happen AFTER auth settles.
          _navigateAfterAuthSettles(uri);
        } else {
          pendingDeepLink = uri;
          _navigateIfReady();
        }
      }
    });

    // Handle runtime deep links (app already running — auth is settled).
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        pendingDeepLink = uri;
        _navigateIfReady();
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  /// Waits for the auth status to emit its first value (settled), then
  /// navigates to the deep link destination. This avoids the race condition
  /// where the '/' StreamBuilder renders LoginScreen before we can navigate.
  void _navigateAfterAuthSettles(Uri uri) {
    final authRepo = getIt<AuthRepository>();
    StreamSubscription<AuthStatus>? sub;
    sub = authRepo.status.listen((status) {
      // The first emission is always the settled status (authenticated or
      // unauthenticated) — the async* generator never yields unknown.
      sub?.cancel();
      debugPrint('Deep Link: auth settled ($status), scheduling navigation to $uri');
      pendingDeepLink = uri;
      _navigateIfReady();
    });
  }

  /// Checks if the navigator is fully mounted and active. If it is, executes
  /// the deep link. Otherwise, schedules a check after 50ms to prevent race
  /// conditions during app boot.
  void _navigateIfReady() {
    if (pendingDeepLink == null) return;

    final navigatorState = appRouter.routerDelegate.navigatorKey.currentState;
    if (navigatorState != null && navigatorState.mounted) {
      final uri = pendingDeepLink!;
      pendingDeepLink = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(uri);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 50), () {
        _navigateIfReady();
      });
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');

    // ── Reset Password ────────────────────────────────────────────────────────
    // Handles: sportigo://reset-password?token=<tok>&email=<email>
    if (uri.scheme == 'sportigo' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];
      if (token != null && email != null) {
        final encoded = Uri.encodeComponent(email);
        appRouter.go('/reset-password?token=$token&email=$encoded');
      }
      return;
    }

    // ── Match Details ─────────────────────────────────────────────────────────
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
    appRouter.push('/match-details', extra: {'matchId': matchId});
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
