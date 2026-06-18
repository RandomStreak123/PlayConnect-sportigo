import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../core/constants/colors.dart';
import '../core/utils/sport_icon_helper.dart';
import '../core/utils/avatar_image_helper.dart';
import '../screens/profile_screen.dart';
import '../data/repositories/auth_repository.dart';

class PlayerRevealCard extends StatefulWidget {
  final int? userId;
  final String playerName;
  final String sportType;
  final String? profilePicture;

  const PlayerRevealCard({
    super.key,
    this.userId,
    this.playerName = 'Player',
    this.sportType = 'Sport',
    this.profilePicture,
  });

  @override
  State<PlayerRevealCard> createState() => _PlayerRevealCardState();
}

class _PlayerRevealCardState extends State<PlayerRevealCard> {
  final List<Map<String, dynamic>> _waves = [];
  int _waveCounter = 0;

  void _addWave() {
    setState(() {
      final id = _waveCounter++;
      _waves.add({
        'id': id,
        'key': UniqueKey(),
      });
    });
  }

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
    final playerName = widget.playerName;
    final profilePicture = widget.profilePicture;
    final userId = widget.userId;
    final sportType = widget.sportType;
    final headerGradient = _getGradientForSport(sportType);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Header + Profile Pic overlap (positioned at the absolute top of the card)
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 140,
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
                        child: SportIconHelper.widgetForSport(
                          sportType,
                          size: 150,
                        ),
                      ),
                    ),
                    // Centered top visual pull bar
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Elegant top-right close circle button
                    Positioned(
                      right: 16,
                      top: 20,
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
                    SportIconHelper.widgetForSport(
                      sportType,
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
          
          const SizedBox(height: 24),
          
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
                    onPressed: userId == null ? null : () async {
                      _addWave();
                      try {
                        final authRepo = context.read<AuthRepository>();
                        await authRepo.waveUser(userId);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to wave at $playerName: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
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
                            userId: userId,
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
    ),
    
    // Floating waving hand emojis layer
    ..._waves.map((wave) {
      return Positioned(
        bottom: 110, // positioned right above the "Send Wave" button
        child: FloatingEmoji(
          key: wave['key'] as Key,
          onComplete: () {
            setState(() {
              _waves.removeWhere((w) => w['id'] == wave['id']);
            });
          },
        ),
      );
    }),
  ],
);
  }
}

class FloatingEmoji extends StatefulWidget {
  final VoidCallback onComplete;

  const FloatingEmoji({required super.key, required this.onComplete});

  @override
  State<FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<FloatingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late double _randomXOffset;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _emoji = '👋';

    // Random horizontal float spread
    _randomXOffset = (math.Random().nextDouble() - 0.5) * 80.0; 

    _yAnimation = Tween<double>(begin: 0.0, end: -250.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_randomXOffset, _yAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                _emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
        );
      },
    );
  }
}
