import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import 'search_match_tile.dart';

class SearchFilterPanel extends StatelessWidget {
  final String selectedSport;
  final String selectedSkill;
  final RangeValues distanceRange;
  final ValueChanged<String> onSportChanged;
  final ValueChanged<String> onSkillChanged;
  final ValueChanged<RangeValues> onDistanceChanged;

  const SearchFilterPanel({
    super.key,
    required this.selectedSport,
    required this.selectedSkill,
    required this.distanceRange,
    required this.onSportChanged,
    required this.onSkillChanged,
    required this.onDistanceChanged,
  });

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: options.map((opt) {
            final isSelected = opt == selectedValue;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(opt);
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primaryContainer 
                      : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        _buildFilterSection(
          context,
          'Sport Type',
          ['All', 'Football', 'Cricket', 'Basketball', 'Tennis', 'Padel', 'Badminton'],
          selectedSport,
          onSportChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildFilterSection(
          context,
          'Skill Level',
          ['All', 'Beginner', 'Intermediate', 'Advanced', 'Professional'],
          selectedSkill,
          onSkillChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        
        Text(
          'Distance (km)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        RangeSlider(
          values: distanceRange,
          min: 0,
          max: 50,
          divisions: 10,
          labels: RangeLabels(
            '${distanceRange.start.round()} km',
            '${distanceRange.end.round()} km',
          ),
          activeColor: Theme.of(context).colorScheme.primaryContainer,
          inactiveColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          onChanged: onDistanceChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        
        Text(
          'Recommended Matches',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        BlocBuilder<MatchBloc, MatchState>(
          builder: (context, state) {
            final recommended = state.matches.take(2).toList();
            if (recommended.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'No matches available right now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: recommended
                  .map((match) => SearchMatchTile(match: match))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
