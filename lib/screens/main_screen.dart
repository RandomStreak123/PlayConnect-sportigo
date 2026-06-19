import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../logic/blocs/activity/activity_bloc.dart';
import '../core/utils/responsive_util.dart';
import '../core/theme/app_spacing.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'matches_screen.dart';
import 'activity_feed_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    MatchesScreen(),
    ActivityFeedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(context),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.explore_rounded, 'Explore')),
              Expanded(child: _buildNavItem(2, Icons.sports_soccer_rounded, 'Matches')),
              Expanded(child: _buildNavItem(3, Icons.dynamic_feed_rounded, 'Activity')),
              Expanded(child: _buildNavItem(4, Icons.person_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final isDesktop = ResponsiveUtil.isDesktop(context);
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _currentIndex = index;
        });
        _onTabChanged(index);
      },
      labelType: isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      extended: isDesktop,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.explore_rounded),
          label: Text('Explore'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sports_soccer_rounded),
          label: Text('Matches'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.dynamic_feed_rounded),
          label: Text('Activity'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_rounded),
          label: Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _onTabChanged(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.xxs),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _onTabChanged(int index) {
    if (!mounted) return;
    switch (index) {
      case 2:
        context.read<MatchBloc>().add(const MyMatchesFetched());
        break;
      case 3:
        context.read<ActivityBloc>().add(const ActivityFetched());
        break;
    }
  }
}
