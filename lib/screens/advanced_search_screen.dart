import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/match_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/match_repository.dart';
import '../core/di/service_locator.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'advanced_search/widgets/search_filter_panel.dart';
import 'advanced_search/widgets/search_results_feed.dart';

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

  Timer? _debounceTimer;
  List<MatchModel> _searchResultsMatches = [];
  List<UserModel> _searchResultsPlayers = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    final state = context.read<MatchBloc>().state;
    _searchController.text = state.search ?? '';
    _selectedSport = state.sportType ?? 'All';
    _selectedSkill = state.skillLevel ?? 'All';
    
    _searchController.addListener(_onSearchChanged);
    
    if (_searchController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(_searchController.text.trim());
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _searchResultsMatches = [];
          _searchResultsPlayers = [];
          _isSearching = false;
          _searchError = null;
        });
      } else {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final matchRepo = getIt<MatchRepository>();
      final authRepo = getIt<AuthRepository>();

      final results = await Future.wait([
        matchRepo.getNearbyMatches(search: query),
        authRepo.getPlayers(search: query),
      ]);

      final matchResults = results[0] as ({List<MatchModel> matches, String? nextCursor});
      final playerResults = results[1] as List<UserModel>;

      if (mounted) {
        setState(() {
          _searchResultsMatches = matchResults.matches;
          _searchResultsPlayers = playerResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = 'Search failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Advanced Search',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search matches, players, or clubs',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.outline),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            
            if (showSearchResults)
              SearchResultsFeed(
                isSearching: _isSearching,
                searchError: _searchError,
                searchResultsPlayers: _searchResultsPlayers,
                searchResultsMatches: _searchResultsMatches,
              )
            else
              SearchFilterPanel(
                selectedSport: _selectedSport,
                selectedSkill: _selectedSkill,
                distanceRange: _distanceRange,
                onSportChanged: (val) => setState(() => _selectedSport = val),
                onSkillChanged: (val) => setState(() => _selectedSkill = val),
                onDistanceChanged: (val) => setState(() => _distanceRange = val),
              ),
            
            const SizedBox(height: AppSpacing.bottomNavClearance),
          ],
        ),
      ),
      bottomSheet: !showSearchResults
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<MatchBloc>().add(MatchFetched(
                                sportType: _selectedSport,
                                skillLevel: _selectedSkill,
                                search: _searchController.text.trim().isEmpty
                                    ? null
                                    : _searchController.text.trim(),
                              ));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
