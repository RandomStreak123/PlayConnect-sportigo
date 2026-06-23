import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class QuickSportShortcuts extends StatelessWidget {
  const QuickSportShortcuts({super.key});

  void _onCategorySelected(BuildContext context, String category) {
    context.read<MatchBloc>().add(MatchFetched(sportType: category));
  }

  Widget _buildCategoryPill(BuildContext context, String selectedSport, String label) {
    final isSelected = selectedSport == label;
    return GestureDetector(
      onTap: () => _onCategorySelected(context, label),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final selectedSport = state.sportType ?? 'All';
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryPill(context, selectedSport, 'All'),
              _buildCategoryPill(context, selectedSport, 'Football'),
              _buildCategoryPill(context, selectedSport, 'Cricket'),
              _buildCategoryPill(context, selectedSport, 'Badminton'),
              _buildCategoryPill(context, selectedSport, 'Basketball'),
              _buildCategoryPill(context, selectedSport, 'Tennis'),
              _buildCategoryPill(context, selectedSport, 'Padel'),
            ],
          ),
        );
      },
    );
  }
}
