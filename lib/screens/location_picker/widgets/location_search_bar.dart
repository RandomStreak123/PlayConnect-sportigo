import 'package:flutter/material.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../core/theme/app_radius.dart';

class LocationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearchPressed;

  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Search location...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSearchPressed(),
              ),
            ),
          ),
          isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: AppLoadingIndicator(),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: onSearchPressed,
                ),
        ],
      ),
    );
  }
}
