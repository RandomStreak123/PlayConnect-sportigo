import 'package:get_it/get_it.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../theme/theme_manager.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // Core Services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(baseUrl: ApiConstants.baseUrl));
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ThemeManager>(() => ThemeManager());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<MatchRepository>(
    () => MatchRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ActivityRepository>(
    () => ActivityRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(apiClient: getIt<ApiClient>()),
  );
}
