import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

/// Standard chip variants for the Sportigo design system.
///
/// [AppChip] — Default chip: used for sport filters, category pills.
///   padding: symmetric(horizontal: 16, vertical: 8)
///
/// [AppStatusChip] — Compact chip: used for skill level badges, organizer labels.
///   padding: symmetric(horizontal: 8, vertical: 4)

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.selectedColor,
    this.unselectedColor,
    this.textStyle,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isSelected
        ? (selectedColor ?? scheme.primaryContainer)
        : (unselectedColor ?? scheme.surface);
    final textColor =
        isSelected ? Colors.white : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,   // 16
          vertical: AppSpacing.xs,    // 8
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? scheme.primaryContainer)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: (textStyle ?? Theme.of(context).textTheme.labelLarge)
              ?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

/// Compact status/badge chip: skill level, organizer label, sport badge.
class AppStatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  const AppStatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,   // 8
        vertical: AppSpacing.xxs,   // 4
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surfaceDim,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: (textStyle ?? Theme.of(context).textTheme.labelSmall)
            ?.copyWith(color: textColor),
      ),
    );
  }
}
