import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../widgets/app_loading_indicator.dart';
import '../screens/match_details_screen.dart';
import 'player_reveal_card.dart';

import '../data/models/match_model.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/utils/sport_image_helper.dart';
import '../core/utils/avatar_image_helper.dart';
import '../core/utils/sport_icon_helper.dart';

class MatchCard extends StatefulWidget {
  final MatchModel match;
  final bool isHorizontal;
  final EdgeInsetsGeometry? margin;
  final bool fromPastMatches;

  const MatchCard({
    super.key,
    required this.match,
    this.isHorizontal = false,
    this.margin,
    this.fromPastMatches = false,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  bool _isSubmitting = false;

  Widget _buildMetadataRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isHorizontal = widget.isHorizontal;
    final margin = widget.margin;

    final paddingVal = isHorizontal ? 12.0 : 16.0;
    final participantCount = match.participants.length;
    final displayAvatarCount = participantCount > 3 ? 3 : participantCount;
    
    final detailsContent = Padding(
      padding: EdgeInsets.all(paddingVal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Skill Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  match.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    fontSize: isHorizontal ? 18.0 : 20.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.skillLevel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: isHorizontal ? 8 : 12),
          
          // Metadata section (Stacked vertically for horizontal mode, side-by-side for vertical mode)
          if (isHorizontal) ...[
            _buildMetadataRow(context, Icons.calendar_today, match.dateTime),
            const SizedBox(height: 6),
            _buildMetadataRow(context, Icons.location_on, match.location),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildMetadataRow(context, Icons.calendar_today, match.dateTime)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetadataRow(context, Icons.location_on, match.location)),
              ],
            ),
          ],
          
          if (isHorizontal) const Spacer(),
          if (!isHorizontal) const SizedBox(height: 20),
          
          // Social Section (Full Width)
          Row(
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
          ),
          
          if (match.slotsLeft > 0) ...[
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final userId = authState.user?.id;
                final userGender = authState.user?.gender;
                final isJoined = match.isJoinedBy(userId);
                final isCreator = (match.creatorId != null && match.creatorId == userId) ||
                    (authState.user != null && match.organizer == authState.user?.name);
                final isRestricted = match.womenOnly && userGender != 'female';

                if (isJoined || isCreator || isRestricted) return const SizedBox.shrink();

                if (_isSubmitting) {
                  return Column(
                    children: [
                      SizedBox(height: isHorizontal ? 8 : 16),
                      SizedBox(
                        width: double.infinity,
                        height: isHorizontal ? 40 : 48,
                        child: const Center(
                          child: AppLoadingIndicator(),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    SizedBox(height: isHorizontal ? 8 : 16),
                    SizedBox(
                      width: double.infinity,
                      height: isHorizontal ? 40 : 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSubmitting = true;
                          });
                          context.read<MatchBloc>().add(
                            MatchJoined(match.id),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isHorizontal ? 12 : 16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Join Match',
                          style: TextStyle(
                            fontSize: isHorizontal ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );

    return BlocListener<MatchBloc, MatchState>(
      listenWhen: (previous, current) => current.message != null,
      listener: (context, state) {
        if (_isSubmitting) {
          setState(() {
            _isSubmitting = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailsScreen(
                match: match,
                fromPastMatches: widget.fromPastMatches,
              ),
            ),
          );
        },
        child: Container(
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Image & Header
              Stack(
                children: [
                  Container(
                    height: isHorizontal ? 110 : 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      image: DecorationImage(
                        image: AssetImage(SportImageHelper.getImageForSport(
                          match.sportType,
                          matchId: match.id.toString(),
                        )),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        // Neutral scrim so women's / lavender theme does not tint photos pink.
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SportIconHelper.widgetForSport(
                                      match.sportType,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      match.sportType,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              if (match.womenOnly)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF4D8D), Color(0xFF7B61FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF4D8D).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '🌸 Women Only',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sportsGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            match.slotsLeft > 0
                                ? '${match.slotsLeft} slots left'
                                : 'Match Full',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              isHorizontal
                  ? Expanded(child: detailsContent)
                  : detailsContent,
            ],
          ),
        ),
      ),
    );
  }
}
