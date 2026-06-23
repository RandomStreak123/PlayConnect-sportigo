import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../widgets/match_card.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../core/theme/app_spacing.dart';

class FeaturedMatchesCarousel extends StatelessWidget {
  const FeaturedMatchesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state.status == MatchStatus.initial ||
            (state.status == MatchStatus.loading && state.matches.isEmpty)) {
          return const SliverFillRemaining(
            child: Center(child: AppLoadingIndicator()),
          );
        }
        if (state.status == MatchStatus.failure) {
          return const SliverFillRemaining(
            child: Center(child: Text('Failed to load matches')),
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
          return const SliverFillRemaining(
            child: Center(child: Text('No upcoming matches found nearby')),
          );
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(380),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: upcomingMatches.length,
              itemBuilder: (context, index) {
                final match = upcomingMatches[index];
                return SizedBox(
                  width: 312,
                  height: MediaQuery.textScalerOf(context).scale(364),
                  child: MatchCard(
                    match: match,
                    isHorizontal: true,
                    margin: EdgeInsets.only(
                      left: index == 0 ? AppSpacing.md : 0.0,
                      right: AppSpacing.sm,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
