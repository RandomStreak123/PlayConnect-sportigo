import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationGroup(context, 'Today'),
          _buildNotificationItem(
            context,
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primaryContainer,
            title: 'Match Reminder',
            message: 'Your Padel match at Downtown Courts starts tonight at 19:00.',
            time: '2h ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            context,
            icon: Icons.person_add_rounded,
            iconColor: AppColors.secondary,
            title: 'New Request',
            message: 'Alex D. wants to join your 3v3 Pickup Game.',
            time: '5h ago',
            isUnread: true,
          ),
          const SizedBox(height: 24),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.outline,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread 
            ? AppColors.primaryContainer.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread 
              ? AppColors.primaryContainer.withValues(alpha: 0.1)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
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
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
