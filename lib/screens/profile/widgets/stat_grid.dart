import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../data/models/user_model.dart';

class StatGrid extends StatelessWidget {
  final bool isCurrentUser;
  final Map<String, dynamic>? publicProfileData;
  final Color sportColor;

  const StatGrid({
    super.key,
    required this.isCurrentUser,
    this.publicProfileData,
    required this.sportColor,
  });

  Widget _buildConcentricIcon(Color color, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard(
    BuildContext context,
    String title,
    String value,
    Widget iconWidget,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconWidget,
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;
    final double childAspectRatio = screenWidth < 360 ? 1.35 : 1.6;

    return BlocSelector<AuthBloc, AuthState, UserModel?>(
      selector: (state) => state.user,
      builder: (context, user) {
        final winRate = publicProfileData?['stats']?['winRate'] as int? ??
            (isCurrentUser ? (user?.stats?.winRate ?? 72) : 0);
        final primarySport = publicProfileData?['primary_sport'] as String? ??
            (isCurrentUser ? user?.primarySport : null) ?? 'None';
        final totalGames = publicProfileData?['stats']?['totalGames'] as int? ??
            (isCurrentUser ? (user?.stats?.totalGames ?? 120) : 0);
        final averageRating = (publicProfileData?['stats']?['averageRating'] as num?)?.toDouble() ??
            (isCurrentUser ? (user?.stats?.averageRating ?? 0.0) : 0.0);
        final averageRatingStr = averageRating.toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
            children: [
              _buildGlassStatCard(
                context,
                'Win Rate',
                '$winRate%',
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
              ),
              _buildGlassStatCard(
                context,
                'Primary Sport',
                primarySport,
                _buildConcentricIcon(AppColors.electricCyan, 20),
              ),
              _buildGlassStatCard(
                context,
                'Total Games',
                '$totalGames',
                Icon(Icons.sports_soccer, color: sportColor, size: 20),
              ),
              _buildGlassStatCard(
                context,
                'Average Rating',
                '$averageRatingStr ⭐',
                const Icon(Icons.star_border_rounded, color: Colors.amber, size: 20),
              ),
            ],
          ),
        );
      }
    );
  }
}
