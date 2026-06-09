import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../core/theme/app_radius.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildNotificationGroup(context, 'Today'),
          _buildNotificationItem(
            context,
            icon: Icons.calendar_today_rounded,
            iconColor: Theme.of(context).colorScheme.primaryContainer,
            title: 'Match Reminder',
            message: 'Your Padel match at Downtown Courts starts tonight at 19:00.',
            time: '2h ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            context,
            icon: Icons.person_add_rounded,
            iconColor: Theme.of(context).colorScheme.secondary,
            title: 'New Request',
            message: 'Alex D. wants to join your 3v3 Pickup Game.',
            time: '5h ago',
            isUnread: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildNotificationGroup(context, 'Yesterday'),
          _buildNotificationItem(
            context,
            icon: Icons.sports_tennis_rounded,
            iconColor: AppColors.warmOrange,
            title: 'Match Found',
            message: 'We found an Intermediate Tennis match matching your skill level near you.',
            time: '1d ago',
            isUnread: false,
          ),
          _buildNotificationItem(
            context,
            icon: Icons.verified_user_rounded,
            iconColor: AppColors.electricCyan,
            title: 'Account Update',
            message: 'Your skill level for Padel has been successfully verified.',
            time: '1d ago',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroup(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isUnread 
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUnread 
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: AppIconSize.sm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
