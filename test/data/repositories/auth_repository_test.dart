import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportigo/data/repositories/auth_repository.dart';
import 'package:sportigo/services/api_client.dart';
import 'package:sportigo/data/models/user_model.dart';
import 'package:sportigo/core/constants/api_constants.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AuthRepository authRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApiClient = MockApiClient();
    authRepository = AuthRepository(apiClient: mockApiClient);
  });

  group('AuthRepository Test', () {
    test('register calls apiClient and returns UserModel', () async {
      final mockUser = UserModel(
        id: 1,
        name: 'John Doe',
        username: 'johndoe',
        email: 'john@example.com',
        phoneNumber: '1234567890',
        gender: 'male',
        skillTier: 'Intermediate',
        primarySport: 'Football',
      );

      final responseBody = {
        'user': mockUser.toJson(),
      };

      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenAnswer((_) async => responseBody);

      final result = await authRepository.register(
        name: 'John Doe',
        username: 'johndoe',
        password: 'password123',
        phoneNumber: '1234567890',
        gender: 'male',
      );

      expect(result.id, mockUser.id);
      expect(result.name, mockUser.name);
      expect(result.username, mockUser.username);

      verify(() => mockApiClient.post(
            ApiConstants.register,
            body: {
              'name': 'John Doe',
              'username': 'johndoe',
              'password': 'password123',
              'phone_number': '1234567890',
              'gender': 'male',
            },
          )).called(1);
    });
  });
}
