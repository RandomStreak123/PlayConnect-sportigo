import 'package:flutter/material.dart';

class ThemeSelector extends StatelessWidget {
  final bool isCurrentUser;
  final int level;
  final Color sportColor;
  final String selectedTheme;
  final Function(String) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.isCurrentUser,
    required this.level,
    required this.sportColor,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCurrentUser || level < 5) {
      return const SizedBox.shrink();
    }

    final availableThemes = ['Default'];
    if (level >= 5) {
      availableThemes.add('Lavender Dusk');
    }
    if (level >= 10) {
      availableThemes.add('Gold Rush');
    }
    if (level >= 25) {
      availableThemes.add('Golden Legend');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: sportColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profile Theme customization',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: availableThemes.map((themeName) {
                final isSelected = selectedTheme == themeName;
                Color chipColor = sportColor;
                if (themeName == 'Lavender Dusk') {
                  chipColor = const Color(0xFF8A2BE2);
                } else if (themeName == 'Gold Rush' || themeName == 'Golden Legend') {
                  chipColor = const Color(0xFFD4AF37);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      themeName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onThemeChanged(themeName);
                      }
                    },
                    selectedColor: chipColor,
                    backgroundColor: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? chipColor : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
