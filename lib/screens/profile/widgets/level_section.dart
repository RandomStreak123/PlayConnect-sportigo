import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../data/models/user_model.dart';

class LevelSection extends StatelessWidget {
  final bool isCurrentUser;
  final Map<String, dynamic>? publicProfileData;
  final Color sportColor;

  const LevelSection({
    super.key,
    required this.isCurrentUser,
    this.publicProfileData,
    required this.sportColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, UserStats?>(
      selector: (state) => state.user?.stats,
      builder: (context, stats) {
        final level = publicProfileData?['stats']?['level'] as int? ??
            (isCurrentUser ? (stats?.level ?? 24) : 1);
        final xp = publicProfileData?['stats']?['currentLevelXp'] as int? ??
            (isCurrentUser ? (stats?.currentLevelXp ?? 750) : 0);
        final nextXp = publicProfileData?['stats']?['nextLevelXp'] as int? ??
            (isCurrentUser ? (stats?.nextLevelXp ?? 1000) : 1000);
        final progressPct = publicProfileData?['stats']?['progressPct'] as int? ??
            (isCurrentUser ? (stats?.progressPct ?? 75) : 0);
        final streak = publicProfileData?['stats']?['streak'] as int? ??
            (isCurrentUser ? (stats?.streak ?? 7) : 0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: sportColor),
                      const SizedBox(width: 6),
                      Text(
                        'Level $level Player',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$xp / $nextXp XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.4),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          height: 10,
                          width: constraints.maxWidth * (progressPct / 100.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [sportColor, AppColors.electricCyan],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Progress to Level ${level + 1}: $progressPct%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '🔥 $streak Match Winning Streak',
                    style: const TextStyle(
                      color: AppColors.warmOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}
