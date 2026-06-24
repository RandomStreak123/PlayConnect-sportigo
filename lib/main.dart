import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/match_repository.dart';
import 'data/repositories/activity_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/matches/match_bloc.dart';
import 'logic/blocs/activity/activity_bloc.dart';
import 'logic/blocs/notification/notification_bloc.dart';
import 'logic/blocs/notification/notification_event.dart';
import 'core/constants/colors.dart';
import 'core/utils/sport_image_helper.dart';
import 'services/deep_link_service.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SportImageHelper.init();
  setupLocator(); // DI Locator boot
  runApp(const PlayConnectApp());
}

class PlayConnectApp extends StatefulWidget {
  const PlayConnectApp({super.key});

  @override
  State<PlayConnectApp> createState() => _PlayConnectAppState();
}

class _PlayConnectAppState extends State<PlayConnectApp> {
  late final DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService()..initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAssets();
    });
  }

  void _precacheAssets() {
    try {
      final paths = SportImageHelper.getAllImagePaths();
      for (final path in paths) {
        precacheImage(AssetImage(path), context);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    getIt<AuthRepository>().dispose();
    getIt<ThemeManager>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<ThemeManager>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: getIt<AuthRepository>())
              ..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => MatchBloc(matchRepository: getIt<MatchRepository>()),
          ),
          BlocProvider(
            create: (_) => ActivityBloc(activityRepository: getIt<ActivityRepository>()),
          ),
          BlocProvider(
            create: (_) => NotificationBloc(
              notificationRepository: getIt<NotificationRepository>(),
            ),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final theme = AppTheme.themeData(themeManager.isWomenMode);

    return MaterialApp.router(
      title: 'PlayConnect',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: appRouter,
      builder: (context, child) {
        return MultiBlocListener(
          listeners: [
            BlocListener<MatchBloc, MatchState>(
              listenWhen: (previous, current) =>
                  current.message != null && current.message != previous.message,
              listener: (context, state) {
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message!),
                      backgroundColor: state.isActionSuccess
                          ? AppColors.sportsGreen
                          : Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  if (state.isActionSuccess) {
                    context.read<AuthBloc>().add(const AuthCheckRequested(forceRefresh: true));
                  } else if (state.message!.toLowerCase().contains('unauthenticated') ||
                      state.message!.toLowerCase().contains('unauthorized')) {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  }
                }
              },
            ),
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) {
                if (previous.user?.gender != current.user?.gender ||
                    previous.user?.themePreference != current.user?.themePreference) {
                  return true;
                }
                if (previous.status == AuthStatus.authenticated &&
                    current.status == AuthStatus.unauthenticated) {
                  return true;
                }
                return previous.status != AuthStatus.authenticated &&
                    current.status == AuthStatus.authenticated;
              },
              listener: (context, state) {
                final themeManager = context.read<ThemeManager>();
                if (state.status == AuthStatus.authenticated &&
                    state.user != null) {
                  themeManager.updateUser(state.user!.gender, state.user!.themePreference);
                  // Load home matches immediately
                  context.read<MatchBloc>().add(const MatchFetched());
                  
                  // Defer background loading of non-critical data
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      context.read<NotificationBloc>().add(const NotificationFetched());
                    }
                  });
                } else if (state.status == AuthStatus.unauthenticated) {
                  themeManager.updateUser(null, null);
                  final currentLocation = appRouter.routerDelegate.currentConfiguration.uri.toString();
                  final isPublicRoute = currentLocation.startsWith('/reset-password') ||
                      currentLocation.startsWith('/register');
                  if (!isPublicRoute) {
                    appRouter.go('/');
                  }
                }
              },
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
