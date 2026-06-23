import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/sport_icon_helper.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/activity_model.dart';

class ActivitySection extends StatefulWidget {
  final bool isCurrentUser;
  final int? userId;
  final Map<String, dynamic>? publicProfileData;
  final Color sportColor;

  const ActivitySection({
    super.key,
    required this.isCurrentUser,
    this.userId,
    this.publicProfileData,
    required this.sportColor,
  });

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  int _activeActivityTab = 0; // 0: Activity, 1: Achievements, 2: Streaks
  bool _showAllActivities = false;
  int _selectedWeekOffset = 0;

  Color _getSportColor(BuildContext context, String sport) {
    switch (sport) {
      case 'Football':
        return AppColors.sportsGreen;
      case 'Cricket':
        return Colors.blue.shade600;
      case 'Basketball':
        return AppColors.warmOrange;
      case 'Tennis':
        return Colors.lime.shade700;
      case 'Padel':
        return Colors.teal;
      case 'Badminton':
        return Colors.purple.shade600;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  int _getActivityXp(String type) {
    if (type == 'match_created') return 35;
    if (type == 'match_joined') return 20;
    if (type == 'match_left') return -20;
    return 0;
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) return 'THIS WEEK';
    if (offset == -1) return 'LAST WEEK';
    
    final now = DateTime.now();
    final targetWeekStart = now.subtract(Duration(days: now.weekday - 1 - (offset * 7)));
    final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));
    
    final startStr = DateFormat('MMM d').format(targetWeekStart);
    final endStr = DateFormat('MMM d').format(targetWeekEnd);
    return '$startStr - $endStr'.toUpperCase();
  }

  Widget _buildTabButton(int index, String label, Color sportColor) {
    final isActive = _activeActivityTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeActivityTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? sportColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? sportColor : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStreakDay(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF2B8A3E) : const Color(0xFFF1F3F5),
          ),
          child: Center(
            child: Icon(
              active ? Icons.check : Icons.close,
              size: 14,
              color: active ? Colors.white : const Color(0xFF868E96),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF868E96),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineActivity({
    required String title,
    required String subtitle,
    required String xpReward,
    required Widget iconWidget,
    required Color sportColor,
  }) {
    final isNegative = xpReward.startsWith('-');
    final pillColor = isNegative ? Colors.redAccent : AppColors.sportsGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              xpReward,
              style: TextStyle(
                color: pillColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(Color sportColor) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, matchState) {
        final List<MatchModel> matchesList = [];
        if (widget.isCurrentUser) {
          matchesList.addAll(matchState.myMatches);
        } else if (widget.publicProfileData?['matches'] != null) {
          final matchesJson = widget.publicProfileData!['matches'] as List<dynamic>;
          matchesList.addAll(
            matchesJson.map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          );
        }

        switch (_activeActivityTab) {
          case 0:
            final activitiesList = <ActivityModel>[];
            if (widget.publicProfileData != null && widget.publicProfileData!['activities'] != null) {
              final activitiesJson = widget.publicProfileData!['activities'] as List<dynamic>;
              activitiesList.addAll(
                activitiesJson.map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
              );
            }

            if (activitiesList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                child: Center(
                  child: Text(
                    'No activity yet. Join or organize a match to get started! ⚽',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final displayedActivities = _showAllActivities 
                ? activitiesList 
                : activitiesList.take(3).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: displayedActivities.length,
                    itemBuilder: (context, index) {
                      final activity = displayedActivities[index];
                      final meta = activity.meta ?? {};
                      final sportType = meta['sport_type'] as String? ?? 'Football';
                      final matchTitle = meta['title'] as String? ?? '';
                      final location = meta['location'] as String? ?? '';
                      final dateStr = _formatDateTime(activity.createdAt.toIso8601String());

                      String title = activity.message;
                      if (activity.type == 'match_created') {
                        title = 'Organized $sportType Match';
                      } else if (activity.type == 'match_joined') {
                        title = 'Joined $sportType Match';
                      } else if (activity.type == 'match_left') {
                        title = 'Left $sportType Match';
                      }

                      String subtitle = '';
                      if (matchTitle.isNotEmpty && location.isNotEmpty) {
                        subtitle = '$matchTitle at $location • $dateStr';
                      } else if (matchTitle.isNotEmpty) {
                        subtitle = '$matchTitle • $dateStr';
                      } else {
                        subtitle = '${activity.message} • $dateStr';
                      }

                      final xp = _getActivityXp(activity.type);
                      final dynamicColor = _getSportColor(context, sportType);

                      return _buildTimelineActivity(
                        title: title,
                        subtitle: subtitle,
                        xpReward: xp >= 0 ? '+$xp XP' : '$xp XP',
                        iconWidget: SportIconHelper.widgetForSport(
                          sportType,
                          size: 28,
                          color: dynamicColor,
                        ),
                        sportColor: dynamicColor,
                      );
                    },
                  ),
                  if (activitiesList.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAllActivities = !_showAllActivities;
                          });
                        },
                        icon: Icon(
                          _showAllActivities ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: sportColor,
                        ),
                        label: Text(
                          _showAllActivities ? 'See Less' : 'See All (${activitiesList.length - 3} more)',
                          style: TextStyle(
                            color: sportColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

          case 1:
            final userForStats = context.read<AuthBloc>().state.user;
            final userLevel = widget.publicProfileData?['stats']?['level'] as int? ??
                (widget.isCurrentUser ? (userForStats?.stats?.level ?? 1) : 1);
            final userStreak = widget.publicProfileData?['stats']?['streak'] as int? ??
                (widget.isCurrentUser ? (userForStats?.stats?.streak ?? 0) : 0);
            final userRating = (widget.publicProfileData?['stats']?['averageRating'] as num?)?.toDouble() ??
                (widget.isCurrentUser ? (userForStats?.stats?.averageRating ?? 0.0) : 0.0);

            final targetUserId = widget.isCurrentUser
                ? context.read<AuthBloc>().state.user?.id
                : widget.userId;

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

          case 2:
            final streakVal = widget.publicProfileData?['stats']?['streak'] as int? ??
                (widget.isCurrentUser ? (context.read<AuthBloc>().state.user?.stats?.streak ?? 0) : 0);

            final playedWeekdays = <int>{};
            final now = DateTime.now();
            final selectedWeekStart = now.subtract(Duration(days: now.weekday - 1 - (_selectedWeekOffset * 7)));
            final selectedWeekMonday = DateTime(selectedWeekStart.year, selectedWeekStart.month, selectedWeekStart.day);
            final selectedWeekSunday = selectedWeekMonday.add(const Duration(days: 7));

            for (final match in matchesList) {
              if (match.isPast) {
                final matchDate = match.parsedDateTime.toLocal();
                if (matchDate.isAfter(selectedWeekMonday.subtract(const Duration(seconds: 1))) && 
                    matchDate.isBefore(selectedWeekSunday)) {
                  playedWeekdays.add(matchDate.weekday);
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🔥 ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$streakVal Match Winning Streak',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Keep playing matches to grow your streak!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2F9E44),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedWeekOffset--;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  color: Colors.transparent,
                                  child: const Text(
                                    '◀',
                                    style: TextStyle(color: Color(0xFF495057), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getWeekLabel(_selectedWeekOffset),
                                style: const TextStyle(
                                  color: Color(0xFF495057),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _selectedWeekOffset < 0
                                    ? () {
                                        setState(() {
                                          _selectedWeekOffset++;
                                        });
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  color: Colors.transparent,
                                  child: Text(
                                    '▶',
                                    style: TextStyle(
                                      color: _selectedWeekOffset < 0 ? const Color(0xFF495057) : const Color(0xFFADB5BD),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStreakDay('M', playedWeekdays.contains(DateTime.monday)),
                        _buildStreakDay('T', playedWeekdays.contains(DateTime.tuesday)),
                        _buildStreakDay('W', playedWeekdays.contains(DateTime.wednesday)),
                        _buildStreakDay('T', playedWeekdays.contains(DateTime.thursday)),
                        _buildStreakDay('F', playedWeekdays.contains(DateTime.friday)),
                        _buildStreakDay('S', playedWeekdays.contains(DateTime.saturday)),
                        _buildStreakDay('S', playedWeekdays.contains(DateTime.sunday)),
                      ],
                    ),
                  ],
                ),
              ),
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTabButton(0, 'Activity Log', widget.sportColor),
                const SizedBox(width: 12),
                _buildTabButton(1, 'Achievements', widget.sportColor),
                const SizedBox(width: 12),
                _buildTabButton(2, 'Streaks', widget.sportColor),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildActiveTabContent(widget.sportColor),
        ),
      ],
    );
  }
}
