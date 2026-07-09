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
        cardSubtitle: '11v11, 7v7 or 5v5 action on grass or turf',
        subtitle:
            'The beautiful game. 11v11, 7v7 or 5v5 action on grass or turf.',
        emoji: '⚽',
        color: const Color(0xFF10B981), // Green
        rules: const [
          SportRule(
            title: 'Fair Play (No Slides)',
            description:
                'Slide tackles are strictly prohibited in recreational play to prevent injury. Stay on your feet!',
          ),
          SportRule(
            title: 'Goal Area & Keepers',
            description:
                'Goalkeepers can only handle the ball inside the designated penalty area. No back-passes can be handled.',
          ),
          SportRule(
            title: 'Restarts',
            description:
                'Kick-ins or throw-ins from the touchline depending on venue style. All free kicks must respect defensive distance.',
          ),
          SportRule(
            title: 'Offside Rule',
            description:
                'Offside is typically not enforced in 5v5/7v7 small-sided matches unless explicitly agreed beforehand.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Cricket',
        cardSubtitle: 'T20 or custom overs format',
        subtitle: 'Bat, bowl, field. T20 or custom overs format.',
        emoji: '🏏',
        color: const Color(0xFF3B82F6), // Blue
        rules: const [
          SportRule(
            title: 'Format & Overs',
            description:
                'Usually played as T20 or custom overs format. Bowlers are restricted to a maximum of 4 overs per match.',
          ),
          SportRule(
            title: 'Scoring Runs',
            description:
                'Runs are scored by running between wickets or hitting boundaries (4 runs on bounce, 6 runs aerial).',
          ),
          SportRule(
            title: 'Extra Penalties',
            description:
                'Wides and No-balls grant 1 extra run to the batting team, and No-balls grant a Free Hit on the next delivery.',
          ),
          SportRule(
            title: 'Dismissal Types',
            description:
                'Batsmen can be dismissed via Bowled, Caught, LBW, Run Out, Stumped, or Hit Wicket.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Badminton',
        cardSubtitle: 'Fast-paced racket sport',
        subtitle:
            'Fast-paced racket sport played over a net with shuttlecocks.',
        emoji: '🏸',
        color: const Color(0xFF8B5CF6), // Purple
        rules: const [
          SportRule(
            title: 'Underhand Serve',
            description:
                'The serve must be hit underhand from below the server\'s waist. The shuttlecock must travel diagonally into the opponent\'s service court.',
          ),
          SportRule(
            title: 'Scoring Format',
            description:
                'Matches are played as best of 3 games of 21 points. A point is scored on every rally (rally scoring).',
          ),
          SportRule(
            title: 'Fault Calls',
            description:
                'It is a fault if the shuttlecock touches the net, lands out of bounds, or if a player touches the net with their body or racket.',
          ),
          SportRule(
            title: 'In or Out',
            description:
                'Shuttlecocks landing on the boundary line are considered in-bounds.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Basketball',
        cardSubtitle: '5v5 full-court or 3v3 half-court play',
        subtitle: 'Hoop action. 5v5 full-court or 3v3 half-court play.',
        emoji: '🏀',
        color: const Color(0xFFF97316), // Orange
        rules: const [
          SportRule(
            title: 'Scoring System',
            description:
                'Matches can be 5v5 full-court or 3v3 half-court. Baskets inside the arc count for 2 points, outside for 3.',
          ),
          SportRule(
            title: 'Dribbling Rules',
            description:
                'Double dribbling and traveling (taking more than 2 steps without dribbling) are violations.',
          ),
          SportRule(
            title: 'Personal Fouls',
            description:
                'Avoid excessive physical contact. Defenders must establish legal guarding position without reaching/blocking.',
          ),
          SportRule(
            title: 'Possession & Clock',
            description:
                'Standard 24-second shot clock (if applicable) or self-refereed turnover flow. Clear the ball past the arc on changes in 3v3.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Tennis',
        cardSubtitle: 'Classic singles or doubles racket game',
        subtitle:
            'Classic singles or doubles racket game on clay, grass, or hard court.',
        emoji: '🎾',
        color: const Color(0xFF06B6D4), // Cyan
        rules: const [
          SportRule(
            title: 'Serving Sequence',
            description:
                'Serve diagonally behind the baseline. If it hits the net tape and lands in the correct box, it is a let (replay).',
          ),
          SportRule(
            title: 'Scoring Format',
            description:
                'Games are scored 15, 30, 40, Game. Winning a set requires winning 6 games, with at least a 2-game lead.',
          ),
          SportRule(
            title: 'Line Calls',
            description:
                'Any ball landing on any part of the boundary line is considered in. Players call lines on their side of the net.',
          ),
          SportRule(
            title: 'Net Play',
            description:
                'No player or their racket may touch the net while the ball is in play. Reaching over the net to hit a ball is a foul.',
          ),
        ],
      ),
      SportRuleItem(
        title: 'Padel',
        cardSubtitle: 'Enclosed doubles racket sport',
        subtitle:
            'Fast-growing enclosed doubles racket sport combining tennis and squash.',
        emoji: '🏓',
        color: const Color(0xFF6366F1), // Indigo
        rules: const [
          SportRule(
            title: 'Court & Equipment',
            description:
                'Played in doubles on an enclosed 10x20m court with glass walls. Padel rackets are solid with no strings.',
          ),
          SportRule(
            title: 'Underhand Service',
            description:
                'Serves must be hit underhand at or below waist level. The ball must bounce once in the diagonally opposite service box.',
          ),
          SportRule(
            title: 'Wall Bounce Rules',
            description:
                'After bouncing in the opponent\'s court, the ball may strike any glass or mesh wall. Direct hits to mesh/glass are out.',
          ),
          SportRule(
            title: 'Deciding Point (Gold)',
            description:
                'If the score reaches Deuce (40-40), a single deciding Golden Point is played. Receivers choose the side.',
          ),
        ],
      ),
    ];

    // Colors matching mockup
    const headerTitleColor = Color(0xFF0F1E4A);

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : headerTitleColor,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: Color(0xFF4285F4), size: 24),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 4,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a sport to view its detailed rules and match guidelines:',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sportsList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
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
