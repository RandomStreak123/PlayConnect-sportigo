import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/match_card.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'create_match_screen.dart';


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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(14),
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
                        Icon(Icons.upcoming_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Upcoming'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 8),
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
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    return MatchCard(match: filteredMatches[index]);
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUpcoming
                        ? Icons.sports_soccer_rounded
                        : Icons.history_toggle_off_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isUpcoming ? 'No Upcoming Matches' : 'No Match History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 32),
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
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
