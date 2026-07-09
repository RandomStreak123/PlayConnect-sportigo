import 'package:flutter/material.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../widgets/app_loading_indicator.dart';

class ActiveMatchActions extends StatelessWidget {
  final MatchModel match;
  final UserModel? user;
  final bool isJoined;
  final bool isCreator;
  final bool isFull;
  final bool isRestricted;
  final bool isSubmitting;
  final String? pendingAction;
  final VoidCallback onLeave;
  final VoidCallback onJoin;

  const ActiveMatchActions({
    super.key,
    required this.match,
    required this.user,
    required this.isJoined,
    required this.isCreator,
    required this.isFull,
    required this.isRestricted,
    required this.isSubmitting,
    required this.pendingAction,
    required this.onLeave,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (isJoined && !isCreator) {
      return OutlinedButton(
        onPressed: isSubmitting ? null : onLeave,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isSubmitting && pendingAction == 'leave'
            ? SizedBox(
                height: 20,
                width: 20,
                child: AppLoadingIndicator(color: Theme.of(context).colorScheme.error),
              )
            : const Text(
                'Leave Match',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      );
    }

    if (isJoined || isCreator) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.sportsGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              isCreator ? 'You created this match' : 'You joined this match',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.sportsGreen,
              ),
            ),
          ),
        ),
      );
    }

    if (isFull) {
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
              'MATCH FULL',
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

    if (isRestricted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          gradient: AppColors.womenOnlyGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.womenOnlyPink.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, color: AppColors.womenOnlyPink, size: AppIconSize.xs + 2),
            SizedBox(width: AppSpacing.xs),
            Text(
              '🌸 Women-Only Match',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.womenOnlyPink,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: isSubmitting ? null : onJoin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
      ),
      child: isSubmitting && pendingAction == 'join'
          ? const SizedBox(
              height: 20,
              width: 20,
              child: AppLoadingIndicator(color: Colors.white),
            )
          : Text(
              'Join Match (${match.slotsLeft} spots left)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}
