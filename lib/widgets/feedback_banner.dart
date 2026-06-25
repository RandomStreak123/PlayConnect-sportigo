import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

class FeedbackBanner extends StatelessWidget {
  final String? successMessage;
  final String? errorMessage;

  const FeedbackBanner({
    super.key,
    this.successMessage,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (successMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFA2E8DD)),
          ),
          child: Text(
            successMessage!,
            style: const TextStyle(
              color: Color(0xFF0E8A74),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .error
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
