import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/sport_icon_helper.dart';
import '../../../data/models/activity_model.dart';

class ActivityLogTab extends StatefulWidget {
  final List<ActivityModel> activitiesList;
  final Color sportColor;

  const ActivityLogTab({
    super.key,
    required this.activitiesList,
    required this.sportColor,
  });

  @override
  State<ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<ActivityLogTab> {
  bool _showAllActivities = false;

  Color _getSportColor(BuildContext context, String sport) {
    switch (sport) {
      case 'Football':
        return AppColors.sportsGreen;
      case 'Cricket':
        return Colors.blue.shade600;
      case 'Basketball':
        return AppColors.warmOrange;
      case 'Tennis':
        return Colors.lime.shade700;
      case 'Padel':
        return Colors.teal;
      case 'Badminton':
        return Colors.purple.shade600;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  int _getActivityXp(String type) {
    if (type == 'match_created') return 35;
    if (type == 'match_joined') return 20;
    if (type == 'match_left') return -20;
    return 0;
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  Widget _buildTimelineActivity({
    required String title,
    required String subtitle,
    required String xpReward,
    required Widget iconWidget,
    required Color sportColor,
  }) {
    final isNegative = xpReward.startsWith('-');
    final pillColor = isNegative ? Colors.redAccent : AppColors.sportsGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              xpReward,
              style: TextStyle(
                color: pillColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activitiesList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Center(
          child: Text(
            'No activity yet. Join or organize a match to get started! ⚽',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final displayedActivities = _showAllActivities 
        ? widget.activitiesList 
        : widget.activitiesList.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: displayedActivities.length,
            itemBuilder: (context, index) {
              final activity = displayedActivities[index];
              final meta = activity.meta ?? {};
              final sportType = meta['sport_type'] as String? ?? 'Football';
              final matchTitle = meta['title'] as String? ?? '';
              final location = meta['location'] as String? ?? '';
              final dateStr = _formatDateTime(activity.createdAt.toIso8601String());

              String title = activity.message;
              if (activity.type == 'match_created') {
                title = 'Organized $sportType Match';
              } else if (activity.type == 'match_joined') {
                title = 'Joined $sportType Match';
              } else if (activity.type == 'match_left') {
                title = 'Left $sportType Match';
              }

              String subtitle = '';
              if (matchTitle.isNotEmpty && location.isNotEmpty) {
                subtitle = '$matchTitle at $location • $dateStr';
              } else if (matchTitle.isNotEmpty) {
                subtitle = '$matchTitle • $dateStr';
              } else {
                subtitle = '${activity.message} • $dateStr';
              }

              final xp = _getActivityXp(activity.type);
              final dynamicColor = _getSportColor(context, sportType);

              return _buildTimelineActivity(
                title: title,
                subtitle: subtitle,
                xpReward: xp >= 0 ? '+$xp XP' : '$xp XP',
                iconWidget: SportIconHelper.widgetForSport(
                  sportType,
                  size: 28,
                  color: dynamicColor,
                ),
                sportColor: dynamicColor,
              );
            },
          ),
          if (widget.activitiesList.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllActivities = !_showAllActivities;
                  });
                },
                icon: Icon(
                  _showAllActivities ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: widget.sportColor,
                ),
                label: Text(
                  _showAllActivities ? 'See Less' : 'See All (${widget.activitiesList.length - 3} more)',
                  style: TextStyle(
                    color: widget.sportColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
