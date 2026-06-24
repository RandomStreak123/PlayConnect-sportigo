import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class MilestoneCard extends StatelessWidget {
  final Map<String, dynamic> milestone;
  final Color sportColor;

  const MilestoneCard({
    required this.milestone,
    required this.sportColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}

class StatBadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;
  final Color sportColor;

  const StatBadgeCard({
    required this.badge,
    required this.sportColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}
