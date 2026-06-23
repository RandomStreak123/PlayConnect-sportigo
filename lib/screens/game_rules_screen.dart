import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/sport_rule_model.dart';
import 'game_rules/widgets/sport_rule_card.dart';

class GameRulesScreen extends StatelessWidget {
  const GameRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Define the sports items based on the provided design and exact user-provided text
    final List<SportRuleItem> sportsList = [
      SportRuleItem(
        title: 'Football',
        cardSubtitle: '5v5/7v7 turf rules and tackle policies',
        subtitle: 'Guidelines for friendly turf matches, scrimmage games, and tournaments.',
        emoji: '⚽',
        color: const Color(0xFF10B981), // Green
        rules: const [
          SportRule(
            title: 'Player Count',
            description: 'Standard turf matches are 5v5 (min 8 players) or 7v7 (min 12 players).',
          ),
          SportRule(
            title: 'Match Duration',
            description: 'Usually played as two halves of 25 or 30 minutes each, with a 5-minute break.',
          ),
          SportRule(
            title: 'Fair Play',
            description: 'Slide tackles are strictly prohibited on artificial turf to prevent injuries.',
          ),
          SportRule(
            title: 'Equipments',
            description: 'Molded studs or turf shoes only. Shin guards are highly recommended.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Cricket',
        cardSubtitle: 'Over limits, bowling direction, and net boundaries',
        subtitle: 'Guidelines for box cricket, turf leagues, and net practice sessions.',
        emoji: '🏏',
        color: const Color(0xFF3B82F6), // Blue
        rules: const [
          SportRule(
            title: 'Overs Limit',
            description: 'Matches are typically 6 to 12 overs per innings, depending on slot duration.',
          ),
          SportRule(
            title: 'Bowler Rules',
            description: 'Each bowler can bowl a maximum of 2 overs in a standard 8-over match.',
          ),
          SportRule(
            title: 'Underarm/Overarm',
            description: 'Specify bowling type (overarm or underarm) in the match description when organizing.',
          ),
          SportRule(
            title: 'Boundary Rules',
            description: 'Direct hits on the net or walls may count as limited runs (e.g., 1 or 2 runs) or outs.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Badminton',
        cardSubtitle: 'Singles/doubles service and scoring system',
        subtitle: 'Rules for indoor singles and doubles badminton matches.',
        emoji: '🏸',
        color: const Color(0xFF8B5CF6), // Purple
        rules: const [
          SportRule(
            title: 'Scoring Format',
            description: 'Best of 3 games. Each game is played to 21 points using rally scoring.',
          ),
          SportRule(
            title: 'Deuce Rule',
            description: 'If the score reaches 20-all, the side that gains a 2-point lead first wins the game.',
          ),
          SportRule(
            title: 'Service',
            description: 'Underhand service only. The shuttle must be struck below the waist level.',
          ),
          SportRule(
            title: 'Double Play',
            description: 'The service court changes dynamically between partners only when winning a point on service.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Basketball',
        cardSubtitle: '3v3 half-court and 5v5 fouls',
        subtitle: 'Guidelines for half-court 3v3 or full-court 5v5 basketball games.',
        emoji: '🏀',
        color: const Color(0xFFF97316), // Orange
        rules: const [
          SportRule(
            title: 'Match Types',
            description: '3v3 is played on a single hoop. 5v5 is played full-court.',
          ),
          SportRule(
            title: 'Scoring',
            description: 'Standard baskets count as 2 points, shots from behind the arc count as 3 points.',
          ),
          SportRule(
            title: 'Fouls & Violations',
            description: 'Double dribble, traveling, and high contact result in turnover of possession.',
          ),
          SportRule(
            title: 'Game Points',
            description: 'First to 21 points (in 3v3) or highest score at the end of four 10-minute quarters.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Tennis',
        cardSubtitle: 'Sets, scoring (15/30/40), and tie-breakers',
        subtitle: 'Singles and doubles rules for clay and hardcourt tennis.',
        emoji: '🎾',
        color: const Color(0xFF06B6D4), // Cyan
        rules: const [
          SportRule(
            title: 'Scoring',
            description: 'Points progress as 15, 30, 40, and Game. Deuce is active at 40-40.',
          ),
          SportRule(
            title: 'Advantage',
            description: 'After deuce, a player must win two consecutive points to win the game.',
          ),
          SportRule(
            title: 'Sets & Match',
            description: 'Played as best-of-3 sets. A set is won by the first player to win 6 games with a 2-game lead.',
          ),
          SportRule(
            title: 'Tie-breaker',
            description: 'At 6-6 in games, a 7-point tiebreaker is played to decide the set.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Padel',
        cardSubtitle: 'Enclosed glass wall rules and underhand service',
        subtitle: 'Rules for doubles padel matches played in enclosed courts.',
        emoji: '🏓',
        color: const Color(0xFF6366F1), // Indigo
        rules: const [
          SportRule(
            title: 'Doubles Format',
            description: 'Padel is predominantly played as a doubles sport on an enclosed court.',
          ),
          SportRule(
            title: 'Service',
            description: 'Must be underhand, struck at or below waist level, and bounce in the opponent\'s crosscourt box.',
          ),
          SportRule(
            title: 'Wall Play',
            description: 'Ball must bounce on the ground before hitting any wall or fence.',
          ),
          SportRule(
            title: 'Rebounds',
            description: 'Players can strike the ball after it rebounds off their own glass walls to return it.',
          ),
        ],
      ),
    ];

    // Colors matching mockup
    const headerTitleColor = Color(0xFF0F1E4A);

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: isDark ? Colors.white : headerTitleColor),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield,
              color: Color(0xFF4285F4),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Game Rules',
              style: TextStyle(
                color: isDark ? Colors.white : headerTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFEBEBF0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 4, vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a sport to view its detailed rules and match guidelines:',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sportsList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final sport = sportsList[index];
                        return SportRuleCard(sport: sport, isDark: isDark);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
