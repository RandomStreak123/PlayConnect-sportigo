import 'package:flutter/material.dart';
import '../../../../data/models/match_model.dart';
import '../../../../widgets/player_reveal_card.dart';
import '../../../../core/utils/avatar_image_helper.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class MatchParticipantsList extends StatelessWidget {
  final MatchModel match;

  const MatchParticipantsList({
    super.key,
    required this.match,
  });

  Widget _buildResultBadge(BuildContext context, String result) {
    Color bgColor;
    Color textColor;
    String label;

    switch (result.toLowerCase()) {
      case 'win':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Win';
        break;
      case 'loss':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = 'Loss';
        break;
      case 'draw':
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF37474F);
        label = 'Draw';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    MatchParticipant participant,
    bool isOrganizer,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlayerRevealCard(
              userId: participant.id,
              playerName: participant.name,
              sportType: match.sportType,
              profilePicture: participant.profilePicture,
            ),
          );
        },
        child: Row(
          children: [
            AvatarImageHelper.circleAvatar(
              path: participant.profilePicture,
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          participant.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.xxs),
                          ),
                          child: Text(
                            'Organizer',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.warmOrange,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    match.skillLevel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (participant.result != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _buildResultBadge(context, participant.result!),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Players (${match.joinedCount}/${match.maxSlots})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (match.participants.isEmpty)
          Text(
            'No players listed yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          ...match.participants.map(
            (p) => _buildPlayerRow(
              context,
              p,
              p.id == match.creatorId,
            ),
          ),
      ],
    );
  }
}
