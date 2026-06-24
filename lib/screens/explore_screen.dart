import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/match_card.dart';
import '../widgets/player_reveal_card.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../core/di/service_locator.dart';
import '../data/models/user_model.dart';
import '../core/utils/avatar_image_helper.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<UserModel> _players = [];
  bool _isLoadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPlayers = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final fetchedPlayers = await authRepository.getPlayers();
      if (mounted) {
        setState(() {
          _players = fetchedPlayers;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Explore',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingPlayers ? null : _loadPlayers,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'Nearby Players',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(160),
              child: _isLoadingPlayers
                  ? const Center(child: AppLoadingIndicator())
                  : _players.isEmpty
                      ? const Center(
                          child: Text(
                            'No players registered yet',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            final player = _players[index];
                            return _buildPlayerCard(
                              context,
                              player.id,
                              player.name,
                              player.gender?.toUpperCase() ?? 'PLAYER',
                              'Proximity Enabled',
                              player.profilePhotoUrl,
                            );
                          },
                        ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'Trending Matches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            BlocBuilder<MatchBloc, MatchState>(
              builder: (context, state) {
                if (state.status == MatchStatus.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: AppLoadingIndicator(),
                    ),
                  );
                }
                if (state.status == MatchStatus.failure) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Failed to load matches'),
                    ),
                  );
                }

                final now = DateTime.now();
                final upcomingMatches = state.matches.where((match) {
                  return match.parsedDateTime.isAfter(now) ||
                      match.parsedDateTime.isAtSameMomentAs(now);
                }).toList();

                // Sort chronologically (closest first)
                upcomingMatches.sort((a, b) => a.parsedDateTime.compareTo(b.parsedDateTime));

                if (upcomingMatches.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('No upcoming matches found'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingMatches.length,
                  itemBuilder: (context, index) {
                    return MatchCard(match: upcomingMatches[index]);
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.bottomNavClearance),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    int? userId,
    String name,
    String sport,
    String distance,
    String? photoUrl,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PlayerRevealCard(
            userId: userId,
            playerName: name,
            sportType: sport,
            profilePicture: photoUrl,
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarImageHelper.circleAvatar(
              path: photoUrl,
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              sport.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primaryContainer,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              distance,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
