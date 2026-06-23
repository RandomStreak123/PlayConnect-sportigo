import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class WomenOnlyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const WomenOnlyToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: value
            ? LinearGradient(
                colors: [
                  const Color(0xFFFF4D8D).withValues(alpha: 0.08),
                  const Color(0xFF7B61FF).withValues(alpha: 0.05),
                ],
              )
            : null,
        color: value ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: value
              ? const Color(0xFFFF4D8D).withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
        title: Row(
          children: [
            Text(
              '🌸',
              style: TextStyle(fontSize: value ? 20 : 16),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text(
              'Women-Only Match',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        subtitle: Text(
          value
              ? 'Only female players can join this match'
              : 'Enable to restrict to women players',
          style: TextStyle(
            fontSize: 12,
            color: value
                ? const Color(0xFFFF4D8D)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        activeThumbColor: const Color(0xFFFF4D8D),
        onChanged: onChanged,
      ),
    );
  }
}
