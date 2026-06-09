import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/utils/sport_icon_helper.dart';
import '../core/utils/avatar_image_helper.dart';
import '../screens/profile_screen.dart';

class PlayerRevealCard extends StatelessWidget {
  final String playerName;
  final String sportType;
  final String? profilePicture;

  const PlayerRevealCard({
    super.key,
    this.playerName = 'Player',
    this.sportType = 'Sport',
    this.profilePicture,
  });

  List<Color> _getGradientForSport(String sport) {
    switch (sport.toLowerCase().trim()) {
      case 'football':
        return const [Color(0xFF2E7D32), Color(0xFF1B5E20)]; // Turf Green
      case 'basketball':
        return const [Color(0xFFFF9100), Color(0xFFDD2C00)]; // Energetic Orange
      case 'tennis':
      case 'padel':
      case 'pedal':
      case 'badminton':
        return const [Color(0xFFAEEA00), Color(0xFF006064)]; // Lime Cyan Padel
      case 'cricket':
        return const [Color(0xFF00B0FF), Color(0xFF0A2240)]; // Electric Cricket Blue
      default:
        return const [Color(0xFF1E3C72), Color(0xFF2A5298)]; // Classic Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerGradient = _getGradientForSport(sportType);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Top visual pull bar (inside the sheet)
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header + Profile Pic overlap
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Stack(
                  children: [
                    // Dynamic Sport Icon Watermark
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(
                          SportIconHelper.iconForSport(sportType),
                          size: 150,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Elegant top-right close circle button
                    Positioned(
                      right: 16,
                      top: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.25),
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Glowing floating Profile Pic
              Positioned(
                bottom: -45,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: theme.colorScheme.surfaceDim,
                      backgroundImage: AvatarImageHelper.provider(profilePicture),
                      onBackgroundImageError: AvatarImageHelper.resolveUrl(profilePicture) != null
                          ? (exception, stackTrace) {}
                          : null,
                      child: AvatarImageHelper.resolveUrl(profilePicture) == null
                          ? const Icon(Icons.person, size: 40, color: Colors.white70)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 55),
          
          // Player name
          Text(
            playerName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Role & Sport Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sport tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      SportIconHelper.iconForSport(sportType),
                      color: theme.colorScheme.primaryContainer,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      sportType.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Participant tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warmOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.warmOrange.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'MATCH PLAYER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warmOrange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Match active status / Bio Quote
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceDim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"Game on! See you at the match. Let\'s play a legendary session!"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Interactive Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // CTA 1: Send Wave
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Waved at $playerName! 👋'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Text('👋', style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'Send a Quick Wave',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // CTA 2: View Profile Link
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            isCurrentUser: false,
                            playerName: playerName,
                            profilePicture: profilePicture,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'View Full Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
