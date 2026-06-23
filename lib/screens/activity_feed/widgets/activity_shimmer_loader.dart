import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class ActivityShimmerLoader extends StatelessWidget {
  const ActivityShimmerLoader({super.key});

  Widget _buildShimmerBlock(BuildContext context, double width, double height, {double radius = AppRadius.xs}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBlock(context, 48, 48, radius: 24),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildShimmerBlock(context, 80, 14, radius: AppRadius.xxs),
                        _buildShimmerBlock(context, 40, 10, radius: AppRadius.xxs),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildShimmerBlock(context, double.infinity, 14, radius: AppRadius.xxs),
                    const SizedBox(height: 6),
                    _buildShimmerBlock(context, 160, 14, radius: AppRadius.xxs),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              _buildShimmerBlock(context, 44, 44, radius: 22),
            ],
          ),
        );
      },
    );
  }
}
