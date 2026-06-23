import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class CreateMatchFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const CreateMatchFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  InputBorder _fieldBorder(BuildContext context, {bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(
        color: focused
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        width: focused ? 2 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.xxs),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? GestureDetector(
                    onTap: onTap,
                    child: Icon(icon, color: Theme.of(context).colorScheme.outline),
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: _fieldBorder(context),
            enabledBorder: _fieldBorder(context),
            focusedBorder: _fieldBorder(context, focused: true),
          ),
        ),
      ],
    );
  }
}
