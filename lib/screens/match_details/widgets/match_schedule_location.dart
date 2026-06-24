import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/match_model.dart';
import '../../../core/theme/app_spacing.dart';

class MatchScheduleLocation extends StatelessWidget {
  final MatchModel match;

  const MatchScheduleLocation({
    super.key,
    required this.match,
  });

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F172A),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDetailRow(
          context,
          Icons.calendar_today_outlined,
          match.dateTime,
          match.skillLevel,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildDetailRow(
          context,
          Icons.location_on_outlined,
          match.location,
          '${match.slotsLeft} slots open • Click to view on Google Maps',
          onTap: () async {
            String searchQuery = match.location;
            if (!searchQuery.toLowerCase().contains('trivandrum') &&
                !searchQuery.toLowerCase().contains('thiruvananthapuram')) {
              searchQuery += ', Thiruvananthapuram';
            }
            final Uri url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchQuery)}',
            );
            try {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (e) {
              try {
                await launchUrl(url, mode: LaunchMode.platformDefault);
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open map.')),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }
}
