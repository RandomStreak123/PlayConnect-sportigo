import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icon_size.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/utils/sport_icon_helper.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '$hrs hr${hrs > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  IconData _getIconForType(String type, String? sportType) {
    if (type == 'match_joined') {
      switch (sportType?.toLowerCase()) {
        case 'football':
          return Icons.sports_soccer_rounded;
        case 'basketball':
          return Icons.sports_basketball_rounded;
        case 'tennis':
          return Icons.sports_tennis_rounded;
        case 'badminton':
          return Icons.sports_tennis;
        case 'cricket':
          return Icons.sports_cricket_rounded;
        default:
          return Icons.sports_rounded;
      }
    } else if (type == 'match_left') {
      return Icons.exit_to_app_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getColorForType(BuildContext context, String type, String? sportType) {
    if (type == 'match_joined') {
      switch (sportType?.toLowerCase()) {
        case 'football':
          return const Color(0xFF4CAF50);
        case 'basketball':
          return const Color(0xFFFF9800);
        case 'tennis':
          return const Color(0xFFCDDC39);
        case 'badminton':
          return const Color(0xFF00BCD4);
        case 'cricket':
          return const Color(0xFF3F51B5);
        default:
          return Theme.of(context).colorScheme.primaryContainer;
      }
    } else if (type == 'match_left') {
      return Colors.redAccent;
    }
    return Theme.of(context).colorScheme.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final meta = notification.meta;
    final sportType = meta?['sport_type'] as String?;
    final iconColor = _getColorForType(context, notification.type, sportType);
    final isUnread = !notification.isRead;

    Widget? iconWidget;
    IconData? iconData;
    if (notification.type == 'match_joined') {
      iconWidget = SportIconHelper.widgetForSport(
        sportType ?? '',
        size: 32,
        color: iconColor,
      );
    } else {
      iconData = _getIconForType(notification.type, sportType);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            iconWidget != null
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: iconWidget),
                  )
                : Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData!, color: iconColor, size: AppIconSize.sm),
                  ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _getRelativeTime(notification.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    notification.message,
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
      ),
    );
  }
}
