import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/avatar_image_helper.dart';
import '../../../data/models/activity_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icon_size.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/sport_icon_helper.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
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

  String _sanitizeMessage(String message) {
    final lastQuoteIndex = message.lastIndexOf('"');
    if (lastQuoteIndex != -1) {
      final suffix = message.substring(lastQuoteIndex + 1);
      if (suffix.trim().startsWith('at ')) {
        return message.substring(0, lastQuoteIndex + 1);
      }
    }
    return message;
  }

  Color _getActivityColor(String type, String? sportType) {
    if (type == 'match_created') {
      return AppColors.sportsGreen;
    } else if (type == 'match_joined') {
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
          return AppColors.sportsGreen;
      }
    } else if (type == 'match_left') {
      return Colors.redAccent;
    }
    return AppColors.deepBlue;
  }

  Widget _getActivityIcon(String type, String? sportType, Color color) {
    if (type == 'match_created') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Icon(Icons.add_circle_outline, color: color, size: AppIconSize.md),
      );
    } else if (type == 'match_left') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Icon(Icons.exit_to_app_rounded, color: color, size: AppIconSize.md),
      );
    } else {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SportIconHelper.widgetForSport(
            sportType ?? '',
            size: 32,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = activity.meta;
    final sportType = meta?['sport_type'] as String?;
    final color = _getActivityColor(activity.type, sportType);

    final Color leftBarColor;
    if (activity.type == 'match_joined') {
      leftBarColor = AppColors.sportsGreen;
    } else if (activity.type == 'match_left') {
      leftBarColor = Colors.redAccent;
    } else {
      leftBarColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leftBarColor != Colors.transparent)
                    Container(
                      width: 4,
                      color: leftBarColor,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AvatarImageHelper.circleAvatar(
                            path: activity.user?.profilePicture,
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        activity.user?.name ?? 'Player',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      _getRelativeTime(activity.createdAt),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _sanitizeMessage(activity.message),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _getActivityIcon(activity.type, sportType, color),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
