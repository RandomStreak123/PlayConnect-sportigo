import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/models/match_model.dart';
import '../../../core/utils/avatar_image_helper.dart';

class RecordResultsSheet extends StatefulWidget {
  final MatchModel match;
  final Function(List<Map<String, dynamic>> resultsPayload) onSave;

  const RecordResultsSheet({
    super.key,
    required this.match,
    required this.onSave,
  });

  @override
  State<RecordResultsSheet> createState() => _RecordResultsSheetState();
}

class _RecordResultsSheetState extends State<RecordResultsSheet> {
  late final Map<int, String> playerResults;

  @override
  void initState() {
    super.initState();
    playerResults = {
      for (var p in widget.match.participants) p.id: p.result ?? '',
    };
  }

  Widget _buildToggleChip({
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
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
                '🏆',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Record Match Results',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap Win, Loss, or Draw for each player. Tap again to deselect.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.match.participants.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = widget.match.participants[index];
                final currentResult = playerResults[p.id] ?? '';

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
                        children: [
                          _buildToggleChip(
                            label: 'Win',
                            selected: currentResult == 'win',
                            selectedColor: const Color(0xFF2E7D32),
                            onTap: () {
                              setState(() {
                                playerResults[p.id] = currentResult == 'win' ? '' : 'win';
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildToggleChip(
                            label: 'Loss',
                            selected: currentResult == 'loss',
                            selectedColor: const Color(0xFFC62828),
                            onTap: () {
                              setState(() {
                                playerResults[p.id] = currentResult == 'loss' ? '' : 'loss';
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildToggleChip(
                            label: 'Draw',
                            selected: currentResult == 'draw',
                            selectedColor: const Color(0xFF546E7A),
                            onTap: () {
                              setState(() {
                                playerResults[p.id] = currentResult == 'draw' ? '' : 'draw';
                              });
                            },
                          ),
                        ],
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
                  onPressed: () {
                    final resultsPayload = playerResults.entries
                        .where((e) => e.value.isNotEmpty)
                        .map((e) => {'user_id': e.key, 'result': e.value})
                        .toList();
                    Navigator.pop(context);
                    widget.onSave(resultsPayload);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Save Results'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
