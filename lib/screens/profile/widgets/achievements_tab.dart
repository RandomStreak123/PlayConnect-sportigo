import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import 'milestone_card.dart';

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
              return MilestoneCard(milestone: milestone, sportColor: sportColor);
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
              return StatBadgeCard(badge: badge, sportColor: sportColor);
            },
          ),
        ],
      ),
    );
  }
}
