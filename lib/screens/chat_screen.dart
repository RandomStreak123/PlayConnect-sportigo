import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/theme/app_spacing.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_square, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New message feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'Active Now',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                children: [
                  _buildActiveUser(context, 'Your Story', true),
                  _buildActiveUser(context, 'Mike', false),
                  _buildActiveUser(context, 'Sarah', false),
                  _buildActiveUser(context, 'Alex', false),
                  _buildActiveUser(context, 'Coach', false),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'Recent',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) {
                return _buildChatItem(
                  context,
                  'Downtown 3v3 Pickup',
                  'Mike: Yeah, I\'ll bring the extra ball. See you guys at 5.',
                  '12:45 PM',
                  unreadCount: 3,
                  isGroup: true,
                );
              } else if (index == 1) {
                return _buildChatItem(
                  context,
                  'Sarah Jenkins',
                  'Great match today! Let\'s hit the courts again next week.',
                  'Yesterday',
                );
              } else if (index == 2) {
                return _buildChatItem(
                  context,
                  'Coach Reynolds',
                  'Don\'t forget to review the drills I sent over.',
                  'Tue',
                );
              } else {
                return _buildChatItem(
                  context,
                  'Weekend Tennis League',
                  'Court 4 is booked for Saturday morning.',
                  'Mon',
                  isGroup: true,
                );
              }
            }, childCount: 4),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildActiveUser(BuildContext context, String name, bool isStory) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing $name\'s story...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isStory
                          ? Theme.of(context).colorScheme.outlineVariant
                          : Theme.of(context).colorScheme.primaryContainer,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxs / 2),
                    child: CircleAvatar(
                      backgroundImage: isStory
                          ? null
                          : const AssetImage('assets/images/player_profile.png'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                      child: isStory
                          ? Icon(Icons.add, color: Theme.of(context).colorScheme.outline)
                          : null,
                    ),
                  ),
                ),
                if (!isStory)
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.sportsGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    String name,
    String message,
    String time, {
    int unreadCount = 0,
    bool isGroup = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: isGroup
                ? null
                : const AssetImage('assets/images/player_profile.png'),
            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
            child: isGroup
                ? Icon(Icons.group, color: Theme.of(context).colorScheme.outline)
                : null,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: unreadCount > 0
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: unreadCount > 0
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening chat with $name...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
