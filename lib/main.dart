import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
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
import 'widgets/app_loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SportImageHelper.init();
  runApp(const PlayConnectApp());
}

class PlayConnectApp extends StatefulWidget {
  const PlayConnectApp({super.key});

  @override
  State<PlayConnectApp> createState() => _PlayConnectAppState();
}

class _PlayConnectAppState extends State<PlayConnectApp> {
  late final AuthRepository _authRepository;
  late final MatchRepository _matchRepository;
  late final ActivityRepository _activityRepository;
  late final NotificationRepository _notificationRepository;
  late final ThemeManager _themeManager;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _matchRepository = MatchRepository();
    _activityRepository = ActivityRepository();
    _notificationRepository = NotificationRepository();
    _themeManager = ThemeManager();
  }

  @override
  void dispose() {
    _authRepository.dispose();
    _themeManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _matchRepository),
        RepositoryProvider.value(value: _activityRepository),
        RepositoryProvider.value(value: _notificationRepository),
      ],
      child: ChangeNotifierProvider.value(
        value: _themeManager,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthBloc(authRepository: _authRepository)
                ..add(const AuthCheckRequested()),
            ),
            BlocProvider(
              create: (_) => MatchBloc(matchRepository: _matchRepository),
            ),
            BlocProvider(
              create: (_) => ActivityBloc(activityRepository: _activityRepository),
            ),
            BlocProvider(
              create: (context) => NotificationBloc(
                notificationRepository: context.read<NotificationRepository>(),
              ),
            ),
          ],
          child: const AppView(),
        ),
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

    return MaterialApp(
      title: 'PlayConnect',
      debugShowCheckedModeBanner: false,
      theme: theme,
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
                }
              },
            ),
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) {
                if (previous.user?.gender != current.user?.gender ||
                    previous.user?.themePreference != current.user?.themePreference) return true;
                return previous.status != AuthStatus.authenticated &&
                    current.status == AuthStatus.authenticated;
              },
              listener: (context, state) {
                final themeManager = context.read<ThemeManager>();
                if (state.status == AuthStatus.authenticated &&
                    state.user != null) {
                  themeManager.updateUser(state.user!.gender, state.user!.themePreference);
                  context.read<MatchBloc>().add(const MatchFetched());
                  context.read<MatchBloc>().add(const MyMatchesFetched());
                  context.read<ActivityBloc>().add(const ActivityFetched());
                  context.read<NotificationBloc>().add(const NotificationFetched());
                } else if (state.status == AuthStatus.unauthenticated) {
                  themeManager.updateUser(null, null);
                }
              },
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          switch (state.status) {
            case AuthStatus.unknown:
              return const Scaffold(
                body: Center(child: AppLoadingIndicator()),
              );
            case AuthStatus.authenticated:
              return const MainScreen();
            case AuthStatus.unauthenticated:
              return const LoginScreen();
          }
        },
      ),
    );
  }
}
