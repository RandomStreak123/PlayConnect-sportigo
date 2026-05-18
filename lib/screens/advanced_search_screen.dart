import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'match_details_screen.dart';
import '../data/models/match_model.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSport = 'All';
  String _selectedSkill = 'All';
  RangeValues _distanceRange = const RangeValues(0, 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Advanced Search',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search matches, players, or clubs',
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFilterSection(
              context,
              'Sport Type',
              ['All', 'Football', 'Basketball', 'Tennis', 'Padel', 'Badminton'],
              _selectedSport,
              (val) => setState(() => _selectedSport = val),
            ),
            const SizedBox(height: 24),
            
            _buildFilterSection(
              context,
              'Skill Level',
              ['All', 'Beginner', 'Intermediate', 'Advanced', 'Pro'],
              _selectedSkill,
              (val) => setState(() => _selectedSkill = val),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Distance (km)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            RangeSlider(
              values: _distanceRange,
              min: 0,
              max: 50,
              divisions: 10,
              labels: RangeLabels(
                '${_distanceRange.start.round()} km',
                '${_distanceRange.end.round()} km',
              ),
              activeColor: AppColors.primaryContainer,
              inactiveColor: AppColors.outlineVariant.withValues(alpha: 0.5),
              onChanged: (values) => setState(() => _distanceRange = values),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Recommended Matches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildRecommendedItem(
              context,
              'Sunset Doubles Bash',
              'Tennis',
              'Central Park Courts',
              '2.5 km',
              '18:30',
            ),
            _buildRecommendedItem(
              context,
              'Morning Padel Drill',
              'Padel',
              'Westside Club',
              '5.1 km',
              '08:00',
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSport = 'All';
                    _selectedSkill = 'All';
                    _distanceRange = const RangeValues(0, 10);
                    _searchController.clear();
                  });
                },
                child: const Text('Reset'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = opt == selectedValue;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(opt);
              },
              selectedColor: AppColors.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected 
                      ? AppColors.primaryContainer 
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendedItem(
    BuildContext context,
    String title,
    String sport,
    String location,
    String distance,
    String time,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(
              match: MatchModel(
                id: 'rec_${title.toLowerCase().replaceAll(' ', '_')}',
                title: title,
                sportType: sport,
                location: location,
                dateTime: 'Today, $time',
                skillLevel: 'Intermediate',
                availableSlots: 2,
                distance: 2.5,
                avatars: [
                  'assets/images/player_profile.png',
                  'assets/images/player_profile.png',
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sport == 'Tennis' ? Icons.sports_tennis : Icons.sports_kabaddi,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Text(
                        '$location · $distance',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
