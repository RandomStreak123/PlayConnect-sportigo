import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_loading_indicator.dart';

import '../data/models/match_model.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'match_card/match_card_header.dart';
import 'match_card/match_card_social.dart';

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
          MatchCardSocial(match: match),
          
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
                            MatchJoined(matchId: match.id, user: authState.user!),
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
          context.push('/match-details', extra: {
            'match': match,
            'fromPastMatches': widget.fromPastMatches,
          });
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
              MatchCardHeader(match: match, isHorizontal: isHorizontal),

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

