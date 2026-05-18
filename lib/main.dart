import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/match_repository.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/matches/match_bloc.dart';
import 'core/constants/colors.dart';
import 'core/utils/sport_image_helper.dart';


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

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _matchRepository = MatchRepository();
  }


  @override
  void dispose() {
    _authRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _matchRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: _authRepository)
              ..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => MatchBloc(matchRepository: _matchRepository)
              ..add(const MatchFetched()),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'PlayConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return BlocListener<MatchBloc, MatchState>(
          listener: (context, state) {
            if (state.status == MatchStatus.actionSuccess ||
                state.status == MatchStatus.actionFailure) {
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    backgroundColor: state.status == MatchStatus.actionSuccess
                        ? AppColors.sportsGreen
                        : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              switch (state.status) {
                case AuthStatus.authenticated:
                  _navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                  break;
                case AuthStatus.unauthenticated:
                  _navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  break;
                case AuthStatus.unknown:
                  break;
              }
            },
            child: child,
          ),
        );
      },
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
