import 'package:flutter/material.dart';

class SportPillSelector extends StatelessWidget {
  final List<Map<String, String>> sports;
  final String? selectedSport;
  final bool isSaving;
  final Color textFieldFillColor;
  final Color textFieldBorderColor;
  final bool isDark;
  final ValueChanged<String?> onSportSelected;

  const SportPillSelector({
    super.key,
    required this.sports,
    required this.selectedSport,
    required this.isSaving,
    required this.textFieldFillColor,
    required this.textFieldBorderColor,
    required this.isDark,
    required this.onSportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sports.map((sport) {
        final name = sport['name']!;
        final emoji = sport['emoji']!;
        final isSelected = selectedSport == name;
        final pillBgColor = isSelected ? const Color(0xFF10B981) : textFieldFillColor;
        final pillBorderColor = isSelected ? const Color(0xFF10B981) : textFieldBorderColor;
        final pillTextColor = isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF475569));

        return GestureDetector(
          onTap: isSaving ? null : () => onSportSelected(name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: pillBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pillBorderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: pillTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
