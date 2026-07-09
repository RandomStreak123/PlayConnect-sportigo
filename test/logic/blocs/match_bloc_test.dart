import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:sportigo/logic/blocs/matches/match_bloc.dart';
import 'package:sportigo/data/repositories/match_repository.dart';
import 'package:sportigo/services/location_service.dart';
import 'package:sportigo/data/models/match_model.dart';

class MockMatchRepository extends Mock implements MatchRepository {}
class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockMatchRepository mockMatchRepository;
  late MockLocationService mockLocationService;
  final getIt = GetIt.instance;

  setUpAll(() {
    registerFallbackValue(Position(
      longitude: 0.0,
      latitude: 0.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ));
  });

  setUp(() {
    mockMatchRepository = MockMatchRepository();
    mockLocationService = MockLocationService();

    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }
    getIt.registerSingleton<LocationService>(mockLocationService);
  });

  tearDown(() {
    getIt.reset();
  });

  group('MatchBloc Test', () {
    final mockMatches = [
      MatchModel(
        id: '1',
        title: 'Football Match',
        sportType: 'Football',
        location: 'Stadium',
        dateTime: '2026-07-06 18:00:00',
        maxSlots: 10,
        joinedCount: 5,
        availableSlots: 5,
        creatorId: 1,
        organizer: 'Alice',
        skillLevel: 'Intermediate',
        participants: [],
        distance: 0.0,
      ),
    ];

    blocTest<MatchBloc, MatchState>(
      'emits MatchStatus.success with matches when MatchFetched is added',
      setUp: () {
        when(() => mockMatchRepository.getNearbyMatches(
              sportType: any(named: 'sportType'),
              skillLevel: any(named: 'skillLevel'),
              search: any(named: 'search'),
              cursor: any(named: 'cursor'),
            )).thenAnswer((_) async => (matches: mockMatches, nextCursor: null as String?));
        
        when(() => mockLocationService.lastUserPosition).thenReturn(null);
        when(() => mockLocationService.getUserPosition()).thenAnswer((_) async => null);
        when(() => mockLocationService.applyDistances(any(), any())).thenAnswer((inv) => inv.positionalArguments[0] as List<MatchModel>);
      },
      build: () => MatchBloc(matchRepository: mockMatchRepository),
      act: (bloc) => bloc.add(const MatchFetched()),
      expect: () => [
        isA<MatchState>().having((s) => s.status, 'status', MatchStatus.loading),
        isA<MatchState>().having((s) => s.status, 'status', MatchStatus.success)
            .having((s) => s.matches, 'matches', mockMatches),
      ],
    );
  });
}
