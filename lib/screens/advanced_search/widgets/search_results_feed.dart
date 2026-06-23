import 'package:flutter/material.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_loading_indicator.dart';
import 'player_search_result_card.dart';
import 'search_match_tile.dart';

class SearchResultsFeed extends StatelessWidget {
  final bool isSearching;
  final String? searchError;
  final List<UserModel> searchResultsPlayers;
  final List<MatchModel> searchResultsMatches;

  const SearchResultsFeed({
    super.key,
    required this.isSearching,
    required this.searchError,
    required this.searchResultsPlayers,
    required this.searchResultsMatches,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: AppLoadingIndicator(),
        ),
      );
    }

    if (searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            searchError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (searchResultsMatches.isEmpty && searchResultsPlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No matches or players found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Try checking your spelling or searching for something else.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searchResultsPlayers.isNotEmpty) ...[
          Text(
            'Players',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(150),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: searchResultsPlayers.length,
              itemBuilder: (context, index) {
                return PlayerSearchResultCard(
                  player: searchResultsPlayers[index],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (searchResultsMatches.isNotEmpty) ...[
          Text(
            'Matches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: searchResultsMatches
                .map((match) => SearchMatchTile(match: match))
                .toList(),
          ),
        ],
      ],
    );
  }
}
