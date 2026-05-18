import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../screens/match_details_screen.dart';
import 'player_reveal_card.dart';

import '../data/models/match_model.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/utils/sport_image_helper.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final bool isHorizontal;
  final EdgeInsetsGeometry? margin;

  const MatchCard({
    super.key,
    required this.match,
    this.isHorizontal = false,
    this.margin,
  });

  Widget _buildMetadataRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
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
    final paddingVal = isHorizontal ? 12.0 : 16.0;
    
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
                  color: AppColors.surfaceDim,
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
          GestureDetector(
            onTap: () {
              // Show Player Reveal
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PlayerRevealCard(),
              );
            },
            child: Row(
              children: [
                // Avatars overlap
                SizedBox(
                  width: 80,
                  height: 60,
                  child: Stack(
                    children:
                        List.generate(
                          match.avatars.length > 3 ? 3 : match.avatars.length,
                          (index) => Positioned(
                            left: index * 20.0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: const CircleAvatar(
                                radius: 16,
                                backgroundImage: AssetImage(
                                  'assets/images/player_profile.png',
                                ),
                              ),
                            ),
                          ),
                        )..add(
                          match.avatars.length > 3
                              ? Positioned(
                                  left: 3 * 20.0,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors
                                          .primaryContainer,
                                      child: Text(
                                        '+${match.avatars.length - 3}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                              : const Positioned(
                                  child: SizedBox.shrink(),
                                ),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.organizer != null
                        ? 'By ${match.organizer}'
                        : 'Organized by Sportigo',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          if (match.slotsLeft > 0) ...[
            SizedBox(height: isHorizontal ? 8 : 16),
            SizedBox(
              width: double.infinity,
              height: isHorizontal ? 40 : 48,
              child: ElevatedButton(
                onPressed: () {
                  context.read<MatchBloc>().add(
                    MatchJoined(match.id),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
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
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(
              match: match,
            ),
          ),
        );
      },
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryContainer.withValues(alpha: 0.7),
                          AppColors.primaryContainer.withValues(alpha: 0.3),
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
                  child: Container(
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
                      children: [
                        const Icon(
                          Icons.sports_basketball,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match.sportType,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
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
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
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
    );
  }
}
