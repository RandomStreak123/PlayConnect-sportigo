import 'package:flutter/material.dart';

class LevelProgressCircle extends StatelessWidget {
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final double radius;
  final Color progressColor;

  const LevelProgressCircle({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    this.radius = 45.0,
    required this.progressColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = nextLevelXp > 0 ? (currentXp / nextLevelXp) : 0.0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CircularProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              strokeWidth: 6,
              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lvl',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
              ),
              Text(
                '$level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
