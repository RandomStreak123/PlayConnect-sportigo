import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/match_card.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'create_match_screen.dart';
import '../core/utils/responsive_util.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_icon_size.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch matches immediately on load
    context.read<MatchBloc>().add(const MyMatchesFetched());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 80,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'My Matches',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TabBar(
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upcoming_rounded, size: AppIconSize.sm - 2),
                        SizedBox(width: AppSpacing.xs),
                        Text('Upcoming'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: AppIconSize.sm - 2),
                        SizedBox(width: AppSpacing.xs),
                        Text('Past Matches'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildMatchTab(isUpcoming: true),
            _buildMatchTab(isUpcoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchTab({required bool isUpcoming}) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state.myMatchesStatus == MatchStatus.loading &&
            state.myMatches.isEmpty) {
          return Center(
            child: AppLoadingIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final now = DateTime.now();

        var filteredMatches = state.myMatches.where((match) {
          final isMatchUpcoming =
              match.parsedDateTime.isAfter(now) ||
              match.parsedDateTime.isAtSameMomentAs(now);
          return isUpcoming ? isMatchUpcoming : !isMatchUpcoming;
        }).toList();

        // Sort matches: Upcoming sorted nearest first, Past sorted most recent first
        if (isUpcoming) {
          filteredMatches.sort(
            (a, b) => a.parsedDateTime.compareTo(b.parsedDateTime),
          );
        } else {
          filteredMatches.sort(
            (a, b) => b.parsedDateTime.compareTo(a.parsedDateTime),
          );
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            context.read<MatchBloc>().add(const MyMatchesFetched());
          },
          child: filteredMatches.isEmpty
              ? _buildEmptyState(isUpcoming)
              : Builder(
                  builder: (context) {
                    final isDesktop = ResponsiveUtil.isDesktop(context);
                    final isTablet = ResponsiveUtil.isTablet(context);
                    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
                    
                    if (crossAxisCount == 1) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          return MatchCard(match: filteredMatches[index]);
                        },
                      );
                    } else {
                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          return MatchCard(match: filteredMatches[index]);
                        },
                      );
                    }
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUpcoming
                        ? Icons.sports_soccer_rounded
                        : Icons.history_toggle_off_rounded,
                    size: AppIconSize.hero + 16,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  isUpcoming ? 'No Upcoming Matches' : 'No Match History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isUpcoming
                      ? 'You have no scheduled matches. Join an existing game or create your own to start playing!'
                      : 'You haven\'t played any matches yet. Once you complete a match, it will be saved here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isUpcoming)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateMatchScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'Create New Match',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
