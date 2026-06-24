import 'package:flutter/material.dart';
import '../../data/models/match_model.dart';
import '../../core/utils/avatar_image_helper.dart';
import '../player_reveal_card.dart';

class MatchCardSocial extends StatelessWidget {
  final MatchModel match;

  const MatchCardSocial({required this.match, super.key});

  @override
  Widget build(BuildContext context) {
    final participantCount = match.participants.length;
    final displayAvatarCount = participantCount > 3 ? 3 : participantCount;

    return Row(
      children: [
        // Avatars overlap
        SizedBox(
          width: 80,
          height: 60,
          child: Stack(
            children: [
              if (displayAvatarCount == 0)
                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: AvatarImageHelper.circleAvatar(
                      path: null,
                      radius: 16,
                    ),
                  ),
                )
              else
                ...List.generate(
                  displayAvatarCount,
                  (index) {
                    final participant = match.participants[index];
                    return Positioned(
                      left: index * 20.0,
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
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: AvatarImageHelper.circleAvatar(
                            path: participant.profilePicture,
                            radius: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (participantCount > 3)
                Positioned(
                  left: 3 * 20.0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context)
                          .colorScheme.primaryContainer,
                      child: Text(
                        '+${participantCount - 3}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              MatchParticipant? organizer;
              for (final p in match.participants) {
                if (p.id == match.creatorId || (match.organizer != null && p.name == match.organizer)) {
                  organizer = p;
                  break;
                }
              }
              if (organizer == null && match.participants.isNotEmpty) {
                organizer = match.participants.first;
              }
              final organizerPhoto = match.organizerPhoto ?? organizer?.profilePicture;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlayerRevealCard(
                  userId: organizer?.id ?? match.creatorId,
                  playerName: match.organizer ?? 'Player',
                  sportType: match.sportType,
                  profilePicture: organizerPhoto,
                ),
              );
            },
            child: Text(
              match.organizer != null
                  ? 'By ${match.organizer}'
                  : 'Organized by Sportigo',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
