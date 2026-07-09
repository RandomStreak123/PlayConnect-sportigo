import 'package:flutter/material.dart';
import '../../../../data/models/match_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class PastMatchActions extends StatelessWidget {
  final MatchModel match;
  final bool fromPastMatches;
  final bool isCreator;
  final bool isJoined;
  final bool hasRated;
  final VoidCallback onRecordResults;
  final VoidCallback onRatePlayers;

  const PastMatchActions({
    super.key,
    required this.match,
    required this.fromPastMatches,
    required this.isCreator,
    required this.isJoined,
    required this.hasRated,
    required this.onRecordResults,
    required this.onRatePlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (fromPastMatches) {
      final hasResults = match.participants.any((p) => p.result != null && p.result!.isNotEmpty);
      if (isCreator) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasResults ? null : onRecordResults,
                  icon: const Icon(Icons.emoji_events, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasResults ? 'Results Updated' : 'Update Results',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasRated ? null : onRatePlayers,
                  icon: const Icon(Icons.star, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasRated ? 'Ratings Submitted' : 'Rate Players',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (isJoined) {
        return SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasRated ? null : onRatePlayers,
            icon: const Icon(Icons.star, size: 20),
            label: Text(hasRated ? 'Ratings Submitted' : 'Rate Players', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        );
      }
    }
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: Text(
            'MATCH COMPLETED',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
