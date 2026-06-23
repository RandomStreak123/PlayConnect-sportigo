import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/activity_model.dart';
import 'activity_log_tab.dart';
import 'achievements_tab.dart';
import 'streaks_tab.dart';

class ActivitySection extends StatefulWidget {
  final bool isCurrentUser;
  final int? userId;
  final Map<String, dynamic>? publicProfileData;
  final Color sportColor;

  const ActivitySection({
    super.key,
    required this.isCurrentUser,
    this.userId,
    this.publicProfileData,
    required this.sportColor,
  });

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  int _activeActivityTab = 0; // 0: Activity, 1: Achievements, 2: Streaks

  Widget _buildTabButton(int index, String label, Color sportColor) {
    final isActive = _activeActivityTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeActivityTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? sportColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? sportColor : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(Color sportColor) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, matchState) {
        final List<MatchModel> matchesList = [];
        if (widget.isCurrentUser) {
          matchesList.addAll(matchState.myMatches);
        } else if (widget.publicProfileData?['matches'] != null) {
          final matchesJson = widget.publicProfileData!['matches'] as List<dynamic>;
          matchesList.addAll(
            matchesJson.map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          );
        }

        switch (_activeActivityTab) {
          case 0:
            final activitiesList = <ActivityModel>[];
            if (widget.publicProfileData != null && widget.publicProfileData!['activities'] != null) {
              final activitiesJson = widget.publicProfileData!['activities'] as List<dynamic>;
              activitiesList.addAll(
                activitiesJson.map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
              );
            }
            return ActivityLogTab(
              activitiesList: activitiesList,
              sportColor: sportColor,
            );

          case 1:
            return AchievementsTab(
              publicProfileData: widget.publicProfileData,
              isCurrentUser: widget.isCurrentUser,
              userId: widget.userId,
              matchesList: matchesList,
              sportColor: sportColor,
            );

          case 2:
            return StreaksTab(
              publicProfileData: widget.publicProfileData,
              isCurrentUser: widget.isCurrentUser,
              matchesList: matchesList,
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTabButton(0, 'Activity Log', widget.sportColor),
                const SizedBox(width: 12),
                _buildTabButton(1, 'Achievements', widget.sportColor),
                const SizedBox(width: 12),
                _buildTabButton(2, 'Streaks', widget.sportColor),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildActiveTabContent(widget.sportColor),
        ),
      ],
    );
  }
}
