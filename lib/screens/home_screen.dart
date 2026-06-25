import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/sign_out_confirmation_sheet.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'advanced_search_screen.dart';
import 'create_match_screen.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/constants/colors.dart';
import 'home/widgets/home_top_bar.dart';
import 'home/widgets/quick_sport_shortcuts.dart';
import 'home/widgets/featured_matches_carousel.dart';
import 'home/widgets/home_match_list.dart';

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
                    HomeTopBar(
                      onProfileTap: () => _showSignOutConfirmation(context),
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
                            const QuickSportShortcuts(),
                            const SizedBox(height: AppSpacing.lg),
                            // Nearby Matches Header
                            Text(
                              'Nearby Matches',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
                    const FeaturedMatchesCarousel(),
                    const HomeMatchList(),
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

  void _showSignOutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SignOutConfirmationSheet(
          onSignOut: () {
            setState(() {
              _isLoggingOut = true;
            });
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
        );
      },
    );
  }
}
