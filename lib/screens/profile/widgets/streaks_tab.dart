import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/match_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';

class StreaksTab extends StatefulWidget {
  final Map<String, dynamic>? publicProfileData;
  final bool isCurrentUser;
  final List<MatchModel> matchesList;

  const StreaksTab({
    super.key,
    required this.publicProfileData,
    required this.isCurrentUser,
    required this.matchesList,
  });

  @override
  State<StreaksTab> createState() => _StreaksTabState();
}

class _StreaksTabState extends State<StreaksTab> {
  int _selectedWeekOffset = 0;

  String _getWeekLabel(int offset) {
    if (offset == 0) return 'THIS WEEK';
    if (offset == -1) return 'LAST WEEK';

    final now = DateTime.now();
    final targetWeekStart = now.subtract(Duration(days: now.weekday - 1 - (offset * 7)));
    final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));

    final startStr = DateFormat('MMM d').format(targetWeekStart);
    final endStr = DateFormat('MMM d').format(targetWeekEnd);
    return '$startStr - $endStr'.toUpperCase();
  }

  Widget _buildStreakDay(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF2B8A3E) : const Color(0xFFF1F3F5),
          ),
          child: Center(
            child: Icon(
              active ? Icons.check : Icons.close,
              size: 14,
              color: active ? Colors.white : const Color(0xFF868E96),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF868E96),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final streakVal = widget.publicProfileData?['stats']?['streak'] as int? ??
        (widget.isCurrentUser ? (context.read<AuthBloc>().state.user?.stats?.streak ?? 0) : 0);

    final playedWeekdays = <int>{};
    final now = DateTime.now();
    final selectedWeekStart = now.subtract(Duration(days: now.weekday - 1 - (_selectedWeekOffset * 7)));
    final selectedWeekMonday = DateTime(selectedWeekStart.year, selectedWeekStart.month, selectedWeekStart.day);
    final selectedWeekSunday = selectedWeekMonday.add(const Duration(days: 7));

    for (final match in widget.matchesList) {
      if (match.isPast) {
        final matchDate = match.parsedDateTime.toLocal();
        if (matchDate.isAfter(selectedWeekMonday.subtract(const Duration(seconds: 1))) &&
            matchDate.isBefore(selectedWeekSunday)) {
          playedWeekdays.add(matchDate.weekday);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '🔥 ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Expanded(
                            child: Text(
                              '$streakVal Match Winning Streak',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep playing matches to grow your streak!',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2F9E44),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWeekOffset--;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: Colors.transparent,
                          child: const Text(
                            '◀',
                            style: TextStyle(color: Color(0xFF495057), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getWeekLabel(_selectedWeekOffset),
                        style: const TextStyle(
                          color: Color(0xFF495057),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _selectedWeekOffset < 0
                            ? () {
                                setState(() {
                                  _selectedWeekOffset++;
                                });
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: Colors.transparent,
                          child: Text(
                            '▶',
                            style: TextStyle(
                              color: _selectedWeekOffset < 0 ? const Color(0xFF495057) : const Color(0xFFADB5BD),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStreakDay('M', playedWeekdays.contains(DateTime.monday)),
                _buildStreakDay('T', playedWeekdays.contains(DateTime.tuesday)),
                _buildStreakDay('W', playedWeekdays.contains(DateTime.wednesday)),
                _buildStreakDay('T', playedWeekdays.contains(DateTime.thursday)),
                _buildStreakDay('F', playedWeekdays.contains(DateTime.friday)),
                _buildStreakDay('S', playedWeekdays.contains(DateTime.saturday)),
                _buildStreakDay('S', playedWeekdays.contains(DateTime.sunday)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
