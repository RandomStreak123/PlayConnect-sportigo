import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/colors.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../widgets/match_card.dart';
import 'notifications_screen.dart';
import 'advanced_search_screen.dart';
import 'create_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    context.read<MatchBloc>().add(MatchFetched(sportType: category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<MatchBloc>().add(const MatchFetched());
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Row(
                  children: [
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final photoUrl = state.user?.profilePhotoUrl;
                        final ImageProvider imageProvider = (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/player_profile.png') as ImageProvider;
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceDim,
                          backgroundImage: imageProvider,
                          onBackgroundImageError: (exception, stackTrace) {
                            // Avoid broken image crashes
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning,',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final name = state.user?.name ?? 'Champ';
                              return Text(
                                name,
                                style: Theme.of(context).textTheme.titleLarge,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.onSurface,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdvancedSearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: AppColors.outline),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Find matches or players...',
                                  style: TextStyle(color: AppColors.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sports Category Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryPill('All'),
                            _buildCategoryPill('Football'),
                            _buildCategoryPill('Cricket'),
                            _buildCategoryPill('Badminton'),
                            _buildCategoryPill('Basketball'),
                            _buildCategoryPill('Tennis'),
                            _buildCategoryPill('Padel'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Nearby Matches Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Matches',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'See All',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.primaryContainer),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              BlocBuilder<MatchBloc, MatchState>(
                builder: (context, state) {
                  if (state.status == MatchStatus.initial) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
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
                      height: 380,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: upcomingMatches.length,
                        itemBuilder: (context, index) {
                          final match = upcomingMatches[index];
                          return SizedBox(
                            width: 312,
                            child: MatchCard(
                              match: match,
                              isHorizontal: true,
                              margin: EdgeInsets.only(
                                left: index == 0 ? 16.0 : 0.0,
                                right: 12.0,
                                top: 8.0,
                                bottom: 8.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Trending Tonight',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              BlocBuilder<MatchBloc, MatchState>(
                builder: (context, state) {
                  final now = DateTime.now();
                  final upcomingMatches = state.matches.where((match) {
                    return match.parsedDateTime.isAfter(now) ||
                        match.parsedDateTime.isAtSameMomentAs(now);
                  }).toList();

                  // Sort chronologically (closest first)
                  upcomingMatches.sort((a, b) => a.parsedDateTime.compareTo(b.parsedDateTime));

                  if (upcomingMatches.isNotEmpty) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final match = upcomingMatches[index % upcomingMatches.length];
                        return MatchCard(
                          match: match,
                        );
                      }, childCount: upcomingMatches.length),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Match',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

