import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/match_card.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/theme/app_spacing.dart';

class HomeMatchList extends StatelessWidget {
  const HomeMatchList({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Trending Matches',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        BlocBuilder<MatchBloc, MatchState>(
          builder: (context, state) {
            final now = DateTime.now();
            final upcomingMatches = state.trendingMatches.where((match) {
              return match.parsedDateTime.isAfter(now) ||
                  match.parsedDateTime.isAtSameMomentAs(now);
            }).toList();

            // Sort chronologically (closest first)
            upcomingMatches.sort((a, b) => a.parsedDateTime.compareTo(b.parsedDateTime));

            if (upcomingMatches.isNotEmpty) {
              final isDesktop = ResponsiveUtil.isDesktop(context);
              final isTablet = ResponsiveUtil.isTablet(context);
              final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
              
              if (crossAxisCount == 1) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final match = upcomingMatches[index % upcomingMatches.length];
                    return MatchCard(match: match);
                  }, childCount: upcomingMatches.length),
                );
              } else {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final match = upcomingMatches[index % upcomingMatches.length];
                      return MatchCard(match: match);
                    }, childCount: upcomingMatches.length),
                  ),
                );
              }
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
        // ── Infinite-scroll footer ─────────────────────────────────
        BlocBuilder<MatchBloc, MatchState>(
          builder: (context, state) {
            if (state.status == MatchStatus.loadingMore) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: AppLoadingIndicator()),
                ),
              );
            }
            if (!state.hasMore && state.matches.isNotEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      '✓  All caught up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }
}
