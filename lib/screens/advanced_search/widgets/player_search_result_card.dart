import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/avatar_image_helper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../widgets/player_reveal_card.dart';

class PlayerSearchResultCard extends StatelessWidget {
  final UserModel player;

  const PlayerSearchResultCard({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = player.profilePhotoUrl;
    final ImageProvider? imageProvider = AvatarImageHelper.provider(photoUrl);
    final sport = player.primarySport ?? player.gender?.toUpperCase() ?? 'PLAYER';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PlayerRevealCard(
            userId: player.id,
            playerName: player.name,
            sportType: sport,
            profilePicture: photoUrl,
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              backgroundImage: imageProvider,
              child: AvatarImageHelper.resolveUrl(photoUrl) == null
                  ? Icon(Icons.person, color: Theme.of(context).colorScheme.primaryContainer)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              player.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              sport.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primaryContainer,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (player.skillTier != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                player.skillTier!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
