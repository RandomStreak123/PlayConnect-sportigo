import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/main_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/registration_screen.dart';
import '../../screens/reset_password_screen.dart';
import '../../screens/match_details_screen.dart';
import '../../screens/advanced_search_screen.dart';
import '../../screens/create_match_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/profile_settings_screen.dart';
import '../../screens/sport_rules_detail_screen.dart';
import '../../data/models/match_model.dart';
import '../../data/models/sport_rule_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../di/service_locator.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final authRepo = getIt<AuthRepository>();
        return StreamBuilder<AuthStatus>(
          stream: authRepo.status,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.data == AuthStatus.authenticated) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        );
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        final email = state.uri.queryParameters['email'];
        final usernameOrEmail = state.uri.queryParameters['username_or_email'];
        return ResetPasswordScreen(
          token: token,
          email: email,
          usernameOrEmail: usernameOrEmail,
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const AdvancedSearchScreen(),
    ),
    GoRoute(
      path: '/create-match',
      builder: (context, state) => const CreateMatchScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final edit = state.uri.queryParameters['edit'] == 'true';
        return ProfileSettingsScreen(showEditProfileOnLoad: edit);
      },
    ),
    GoRoute(
      path: '/match-details',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is MatchModel) {
          return MatchDetailsScreen(match: extra);
        } else if (extra is Map<String, dynamic>) {
          return MatchDetailsScreen(
            match: extra['match'] as MatchModel?,
            matchId: extra['matchId'] as String?,
          );
        } else {
          final queryId = state.uri.queryParameters['id'];
          return MatchDetailsScreen(matchId: queryId);
        }
      },
    ),
    GoRoute(
      path: '/rules-detail',
      builder: (context, state) {
        final sport = state.extra as SportRuleItem;
        return SportRulesDetailScreen(sport: sport);
      },
    ),
  ],
);
