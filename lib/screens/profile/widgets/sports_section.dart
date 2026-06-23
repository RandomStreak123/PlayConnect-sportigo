import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/sport_icon_helper.dart';

class SportsSection extends StatelessWidget {
  final String selectedSport;
  final Function(String) onSportSelected;
  final List<Map<String, dynamic>> sportsList;

  const SportsSection({
    super.key,
    required this.selectedSport,
    required this.onSportSelected,
    required this.sportsList,
  });

  Color _getSportColor(BuildContext context, String sport) {
    switch (sport) {
      case 'Football':
        return AppColors.sportsGreen;
      case 'Cricket':
        return Colors.blue.shade600;
      case 'Basketball':
        return AppColors.warmOrange;
      case 'Tennis':
        return Colors.lime.shade700;
      case 'Padel':
        return Colors.teal;
      case 'Badminton':
        return Colors.purple.shade600;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 12.0),
          child: Text(
            'Favorite Sports Interests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sportsList.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final sportItem = sportsList[index];
              final isSelected = selectedSport == sportItem['name'];
              final dynamicColor = _getSportColor(context, sportItem['name']);
              
              return GestureDetector(
                onTap: () => onSportSelected(sportItem['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? dynamicColor
                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? dynamicColor
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: dynamicColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      SportIconHelper.widgetForSport(
                        sportItem['name']!,
                        size: 16,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sportItem['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
