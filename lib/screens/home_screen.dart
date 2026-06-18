import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/match_card.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../logic/blocs/notification/notification_bloc.dart';
import '../logic/blocs/notification/notification_state.dart';
import 'notifications_screen.dart';
import 'advanced_search_screen.dart';
import 'create_match_screen.dart';
import '../core/utils/responsive_util.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/constants/colors.dart';
import '../core/utils/avatar_image_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Fire load-more when within 300px of the bottom
    if (currentScroll >= maxScroll - 300) {
      context.read<MatchBloc>().add(const MatchFetchedMore());
    }
  }

  void _onCategorySelected(String category) {
    context.read<MatchBloc>().add(MatchFetched(sportType: category));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoggingOut,
      child: Stack(
        children: [
          Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<MatchBloc>().add(const MatchFetched(forceRefresh: true));
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                floating: true,
                toolbarHeight: 72,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                title: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showSignOutConfirmation(context),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final photoUrl = state.user?.profilePhotoUrl;
                          return AvatarImageHelper.circleAvatar(
                            path: photoUrl,
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, notificationState) {
                        final hasUnread = notificationState.notifications.any((n) => !n.isRead);
                        
                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: const Color(0xFFFFD700), // Golden yellow
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
                              if (hasUnread)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.deepBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.surface,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Find matches or players...',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Sports Category Pills
                      BlocBuilder<MatchBloc, MatchState>(
                        builder: (context, state) {
                          final selectedSport = state.sportType ?? 'All';
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryPill(selectedSport, 'All'),
                                _buildCategoryPill(selectedSport, 'Football'),
                                _buildCategoryPill(selectedSport, 'Cricket'),
                                _buildCategoryPill(selectedSport, 'Badminton'),
                                _buildCategoryPill(selectedSport, 'Basketball'),
                                _buildCategoryPill(selectedSport, 'Tennis'),
                                _buildCategoryPill(selectedSport, 'Padel'),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Nearby Matches Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Matches',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          // TextButton(
                          //   onPressed: () {},
                          //   child: Text(
                          //     'See All',
                          //     style: Theme.of(context).textTheme.labelLarge
                          //         ?.copyWith(color: Theme.of(context).colorScheme.primaryContainer),
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              BlocBuilder<MatchBloc, MatchState>(
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
              ),
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
              const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.bottomNavClearance)),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Match',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
          ),
          if (_isLoggingOut)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLoadingIndicator(
                          color: AppColors.sportsGreen,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Signing out...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String selectedSport, String label) {
    final isSelected = selectedSport == label;
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign Out?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to log in again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isLoggingOut = true;
                        });
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
