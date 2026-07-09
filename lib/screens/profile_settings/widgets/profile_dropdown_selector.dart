import 'package:flutter/material.dart';

class ProfileDropdownSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool isDark;
  final Color fillColor;
  final InputBorder borderStyle;
  final InputBorder focusedBorderStyle;

  const ProfileDropdownSelector({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
    required this.fillColor,
    required this.borderStyle,
    required this.focusedBorderStyle,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
          decoration: InputDecoration(
            border: borderStyle,
            enabledBorder: borderStyle,
            focusedBorder: focusedBorderStyle,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          dropdownColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
