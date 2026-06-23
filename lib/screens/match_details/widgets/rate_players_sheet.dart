import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/match_model.dart';
import '../../../core/utils/avatar_image_helper.dart';

class RatePlayersSheet extends StatefulWidget {
  final MatchModel match;
  final int? currentUserId;
  final Function(List<Map<String, dynamic>> ratingsPayload) onSave;

  const RatePlayersSheet({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.onSave,
  });

  @override
  State<RatePlayersSheet> createState() => _RatePlayersSheetState();
}

class _RatePlayersSheetState extends State<RatePlayersSheet> {
  late final List<MatchParticipant> rateableParticipants;
  final Map<int, int> playerRatings = {};

  @override
  void initState() {
    super.initState();
    rateableParticipants = widget.match.participants.where((p) => p.id != widget.currentUserId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text(
                '⭐',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Rate Players',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Rate each player from 1 to 5 stars. You earn +10 XP per player rated!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rateableParticipants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No other players to rate.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rateableParticipants.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = rateableParticipants[index];
                  final currentRating = playerRatings[p.id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        AvatarImageHelper.circleAvatar(
                          path: p.profilePicture,
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            p.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (starIndex) {
                            final starVal = starIndex + 1;
                            final isSelected = currentRating >= starVal;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  playerRatings[p.id] = starVal;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Icon(
                                  isSelected ? Icons.star : Icons.star_border,
                                  color: isSelected ? Colors.amber : Colors.grey.shade300,
                                  size: 28,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: rateableParticipants.isEmpty
                      ? null
                      : () {
                          final ratingsPayload = playerRatings.entries
                              .where((e) => e.value > 0)
                              .map((e) => {'user_id': e.key, 'rating': e.value})
                              .toList();
                          Navigator.pop(context);
                          widget.onSave(ratingsPayload);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Submit Ratings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
