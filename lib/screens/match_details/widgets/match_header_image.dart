import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/models/match_model.dart';
import '../../../../core/utils/sport_image_helper.dart';
import '../../../../core/theme/app_spacing.dart';

class MatchHeaderImage extends StatelessWidget {
  final MatchModel match;

  const MatchHeaderImage({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              SportImageHelper.getImageForSport(match.sportType),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Theme.of(context).colorScheme.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            child: IconButton(
              icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                final shareUrl = 'https://sportigo.com/matches/${match.id}';
                Share.share(
                  'Join my ${match.sportType} match "${match.title}" at ${match.location}! $shareUrl',
                  subject: 'Join my Sportigo match!',
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
