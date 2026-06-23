import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/match_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';

class AchievementsTab extends StatelessWidget {
  final Map<String, dynamic>? publicProfileData;
  final bool isCurrentUser;
  final int? userId;
  final List<MatchModel> matchesList;
  final Color sportColor;

  const AchievementsTab({
    super.key,
    required this.publicProfileData,
    required this.isCurrentUser,
    this.userId,
    required this.matchesList,
    required this.sportColor,
  });

  @override
  Widget build(BuildContext context) {
    final userForStats = context.read<AuthBloc>().state.user;
    final userLevel = publicProfileData?['stats']?['level'] as int? ??
        (isCurrentUser ? (userForStats?.stats?.level ?? 1) : 1);
    final userStreak = publicProfileData?['stats']?['streak'] as int? ??
        (isCurrentUser ? (userForStats?.stats?.streak ?? 0) : 0);
    final userRating = (publicProfileData?['stats']?['averageRating'] as num?)?.toDouble() ??
        (isCurrentUser ? (userForStats?.stats?.averageRating ?? 0.0) : 0.0);

    final targetUserId = isCurrentUser
        ? context.read<AuthBloc>().state.user?.id
        : userId;

    final pastMatchesList = matchesList.where((m) => m.isPast).toList();
    final createdMatchesCount = pastMatchesList.where((m) => m.creatorId == targetUserId).length;
    final totalPlayedGames = pastMatchesList.length;
    
    final createRatio = totalPlayedGames > 0 ? (createdMatchesCount / totalPlayedGames) : 0.0;
    final isCommunityPillar = createRatio >= 0.40;

    int winStreak = 0;
    final sortedPast = List<MatchModel>.from(pastMatchesList);
    sortedPast.sort((a, b) => b.parsedDateTime.compareTo(a.parsedDateTime));
    for (final m in sortedPast) {
      bool isWin = false;
      try {
        final p = m.participants.firstWhere((part) => part.id == targetUserId);
        if (p.result == 'win') {
          isWin = true;
        } else if (p.result == 'loss' || p.result == 'draw') {
          break;
        }
      } catch (_) {
        break;
      }
      if (isWin) {
        winStreak++;
      }
    }
    final finalStreak = winStreak > 0 ? winStreak : userStreak;
    final isInvincible = finalStreak >= 5;

    final isFairPlayAmbassador = userRating >= 4.5 && totalPlayedGames >= 5;

    final uniqueSportsPlayed = pastMatchesList.map((m) => m.sportType.trim().toLowerCase()).toSet();
    final isAllRounder = uniqueSportsPlayed.length >= 3;

    final List<Map<String, dynamic>> levelMilestones = [
      {
        'level': 1,
        'title': 'Rookie Athlete',
        'req': '0+ XP',
        'desc': "You've taken your first steps on the court. Join local matches to earn XP and level up!",
        'rewards': 'Rookie Badge 👟',
        'badge': '👟',
        'unlocked': userLevel >= 1,
      },
      {
        'level': 2,
        'title': 'Rising Star',
        'req': '1,000+ XP',
        'desc': 'Unlocked for active participants. Your dedication is showing. Unlocks basic profile customization features (like active themes).',
        'rewards': 'Rising Star Badge 💫, Theme Selector',
        'badge': '💫',
        'unlocked': userLevel >= 2,
      },
      {
        'level': 5,
        'title': 'Seasoned Veteran',
        'req': '4,000+ XP',
        'desc': 'Unlocked for experienced players. You have a deep history of matchups. Unlocks the Silver Profile Frame and access to co-hosting matches.',
        'rewards': 'Veteran Badge 🎖️, Silver Frame, Lavender Dusk Theme',
        'badge': '🎖️',
        'unlocked': userLevel >= 5,
      },
      {
        'level': 10,
        'title': 'Elite Competitor',
        'req': '9,000+ XP',
        'desc': 'Unlocked for master players. You are a regular face in the community. Unlocks the Gold Profile Badge and custom status options on your profile card.',
        'rewards': 'Gold Badge 🥇, Gold Rush Theme',
        'badge': '🥇',
        'unlocked': userLevel >= 10,
      },
      {
        'level': 25,
        'title': 'Sportigo Legend',
        'req': '24,000+ XP',
        'desc': 'The ultimate milestone. Reserved for the most dedicated athletes. Unlocks the premium Golden Profile Theme (with custom ambient animations) and high-priority badge on the match lobbies you organize.',
        'rewards': 'Legend Badge 🏆, Golden Theme & Frame, Ambient animations',
        'badge': '🏆',
        'unlocked': userLevel >= 25,
      },
    ];

    final List<Map<String, dynamic>> statBadges = [
      {
        'emoji': '👑',
        'title': 'Community Pillar',
        'req': 'Organize 40%+ of played games',
        'desc': 'Awarded to players who actively bring people together by organizing games. You are the heartbeat of the local sports community!',
        'unlocked': isCommunityPillar,
        'progress': 'Current: ${totalPlayedGames > 0 ? ((createdMatchesCount / totalPlayedGames) * 100).toStringAsFixed(0) : "0"}%',
      },
      {
        'emoji': '🔥',
        'title': 'Invincible',
        'req': 'Win streak of 5+ games',
        'desc': 'Awarded to players on a dominant winning run. There is no stopping you right now!',
        'unlocked': isInvincible,
        'progress': 'Current streak: $finalStreak',
      },
      {
        'emoji': '🤝',
        'title': 'Fair Play Ambassador',
        'req': 'Average rating of 4.5+ (over 5+ games)',
        'desc': 'Awarded for excellent sportsmanship, friendliness, and reliable play style as rated by other community members.',
        'unlocked': isFairPlayAmbassador,
        'progress': 'Rating: ${userRating.toStringAsFixed(1)} ⭐ (Games: $totalPlayedGames)',
      },
      {
        'emoji': '🏅',
        'title': 'Ultimate All-Rounder',
        'req': 'Play 3+ different sport types',
        'desc': "You don't stick to just one game. You dominate across multiple courts and disciplines!",
        'unlocked': isAllRounder,
        'progress': 'Sports: ${uniqueSportsPlayed.length}',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Level Progression Milestones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: levelMilestones.length,
            itemBuilder: (context, index) {
              final milestone = levelMilestones[index];
              final isUnlocked = milestone['unlocked'] as bool;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: isUnlocked ? 0.75 : 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnlocked
                        ? sportColor.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: isUnlocked ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: isUnlocked ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isUnlocked ? sportColor : Theme.of(context).colorScheme.surfaceDim).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          milestone['badge'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${milestone['level']}: ${milestone['title']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isUnlocked
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isUnlocked ? AppColors.sportsGreen : Colors.grey).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isUnlocked ? 'UNLOCKED' : 'LOCKED',
                                  style: TextStyle(
                                    color: isUnlocked ? AppColors.sportsGreen : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Requirement: ${milestone['req']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: sportColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            milestone['desc'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnlocked
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Rewards: ${milestone['rewards']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isUnlocked
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Stat-Based Achievements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: statBadges.length,
            itemBuilder: (context, index) {
              final badge = statBadges[index];
              final isUnlocked = badge['unlocked'] as bool;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: isUnlocked ? 0.75 : 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isUnlocked
                        ? sportColor.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: isUnlocked ? 1.5 : 1,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: sportColor.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Opacity(
                          opacity: isUnlocked ? 1.0 : 0.4,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isUnlocked ? sportColor : Theme.of(context).colorScheme.surfaceDim).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badge['emoji'] as String,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isUnlocked ? AppColors.sportsGreen : Colors.grey).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isUnlocked ? 'ACTIVE' : 'LOCKED',
                            style: TextStyle(
                              color: isUnlocked ? AppColors.sportsGreen : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      badge['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isUnlocked
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge['req'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: sportColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        badge['desc'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnlocked
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          height: 1.3,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge['progress'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
