import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

/// Standard text field with consistent padding for the Sportigo design system.
///
/// contentPadding: symmetric(horizontal: 16, vertical: 16) for all
/// TextFields, DropdownButton, and form components.
class AppTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool fixedHeight;

  const AppTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.fixedHeight = false,
  });

  OutlineInputBorder _border(BuildContext context, {bool focused = false}) {
    final scheme = Theme.of(context).colorScheme;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(
        color: focused ? scheme.primary : scheme.outlineVariant,
        width: focused ? 1.5 : 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      focusNode: focusNode,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: scheme.outline)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,   // 16
          vertical: AppSpacing.md,    // 16
        ),
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context, focused: true),
        errorBorder: _border(context),
        focusedErrorBorder: _border(context, focused: true),
      ),
    );

    if (!fixedHeight) return field;
    return SizedBox(height: 52, child: field);
  }
}

/// Standard dropdown with consistent padding.
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final double height;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: Theme.of(context).textTheme.bodyLarge,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
