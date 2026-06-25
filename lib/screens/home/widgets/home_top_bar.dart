import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/notification/notification_bloc.dart';
import '../../../logic/blocs/notification/notification_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/avatar_image_helper.dart';

class HomeTopBar extends StatelessWidget {
  final VoidCallback onProfileTap;

  const HomeTopBar({
    super.key,
    required this.onProfileTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      toolbarHeight: 72,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: BlocSelector<AuthBloc, AuthState, String?>(
              selector: (state) => state.user?.profilePhotoUrl,
              builder: (context, photoUrl) {
                return AvatarImageHelper.circleAvatar(
                  path: photoUrl,
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                BlocSelector<AuthBloc, AuthState, String>(
                  selector: (state) => state.user?.name ?? 'Champ',
                  builder: (context, userName) {
                    return Text(
                      userName,
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: BlocSelector<NotificationBloc, NotificationState, bool>(
            selector: (notificationState) {
              return notificationState.notifications.any((n) => !n.isRead);
            },
            builder: (context, hasUnread) {
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFFFFD700), // Golden yellow
                      ),
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.deepBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
