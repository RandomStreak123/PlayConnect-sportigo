import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/colors.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  String _selectedSport = 'Football';
  int _activeActivityTab = 0; // 0: Activity, 1: Achievements, 2: Streaks
  late AnimationController _animationController;
  
  // Implicit animation trigger states
  bool _isEditButtonHovered = false;
  bool _isShareButtonHovered = false;

  final List<Map<String, dynamic>> _sportsList = [
    {'name': 'Football', 'icon': '⚽'},
    {'name': 'Cricket', 'icon': '🏏'},
    {'name': 'Badminton', 'icon': '🏸'},
    {'name': 'Basketball', 'icon': '🏀'},
    {'name': 'Tennis', 'icon': '🎾'},
    {'name': 'Padel', 'icon': '🏓'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getSportColor(String sport) {
    switch (sport) {
      case 'Football':
        return AppColors.sportsGreen;
      case 'Cricket':
        return Colors.blue.shade600;
      case 'Basketball':
        return AppColors.warmOrange;
      case 'Tennis':
        return Colors.lime.shade700;
      case 'Padel':
        return Colors.teal;
      case 'Badminton':
        return Colors.purple.shade600;
      default:
        return AppColors.primaryContainer;
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final authRepository = context.read<AuthRepository>();

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SafeArea(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.primaryContainer),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primaryContainer),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final updatedUser = await authRepository.uploadProfilePhoto(pickedFile.path);

      if (!mounted) return;

      authBloc.add(AuthUserUpdated(updatedUser));
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: AppColors.sportsGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to upload profile photo: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportColor = _getSportColor(_selectedSport);
    
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background based on dynamic sport type colors
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  sportColor.withValues(alpha: 0.15),
                  AppColors.background.withValues(alpha: 0.9),
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // App Bar / Title Header
                  _buildCustomAppBar(context),
                  
                  // Large Premium Profile Card with neon details
                  _buildLargeProfileCard(context, sportColor),
                  
                  // Complete Identity & Level Progression System
                  _buildLevelSection(context, sportColor),
                  
                  // Premium Stat/Achievement Grid
                  _buildStatGrid(context, sportColor),
                  
                  // Dynamic Social Engagement / Action Cards
                  _buildSocialProofRow(context, sportColor),
                  
                  // Interactive Sport Chips Section
                  _buildSportsSection(context, sportColor),
                  
                  // Responsive Segmented Activity/Streaks Section
                  _buildActivitySection(context, sportColor),
                  
                  // Menu Settings Panel
                  _buildSettingsPanel(context, sportColor),
                  
                  const SizedBox(height: 100), // Padding for elegant floating bottom navigation
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Player Profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.onSurface,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.onSurface),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings feature coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeProfileCard(BuildContext context, Color sportColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sportColor.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Elegant diagonal background accents
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: sportColor.withValues(alpha: 0.04),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar Frame with dynamic glowing pulsing ring
                Center(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final photoUrl = state.user?.profilePhotoUrl;
                      final ImageProvider imageProvider = (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/images/player_profile.png') as ImageProvider;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow border effect
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 146,
                            height: 146,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  sportColor,
                                  sportColor.withValues(alpha: 0.4),
                                  AppColors.electricCyan,
                                  sportColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: sportColor.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          
                          // Inner clean gap
                          Container(
                            width: 136,
                            height: 136,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                            ),
                          ),
                          
                          // Image container
                          GestureDetector(
                            onTap: _isUploading ? null : () => _pickAndUploadImage(context),
                            child: Hero(
                              tag: 'profile_avatar_hero',
                              child: Container(
                                width: 126,
                                height: 126,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) {},
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Dynamic active online badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.sportsGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.sportsGreen.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Floating Edit Photo Button
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _isEditButtonHovered = true),
                              onTapUp: (_) => setState(() => _isEditButtonHovered = false),
                              onTapCancel: () => setState(() => _isEditButtonHovered = false),
                              onTap: _isUploading ? null : () => _pickAndUploadImage(context),
                              child: AnimatedScale(
                                scale: _isEditButtonHovered ? 0.85 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [sportColor, AppColors.electricCyan],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: sportColor.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name, verified check, and country flag
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final userName = state.user?.name ?? 'Sportigo Champ';
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.electricCyan,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.primary,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🔥 PRO PLAYER',
                              style: TextStyle(
                                color: sportColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '🇮🇳 Kochi, IN',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context, Color sportColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: sportColor),
                  const SizedBox(width: 6),
                  Text(
                    'Level 24 Player',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '750 / 1000 XP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // XP linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: AppColors.surfaceDim.withValues(alpha: 0.4),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 10,
                  width: MediaQuery.of(context).size.width * 0.68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [sportColor, AppColors.electricCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Completion meter helper text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level 25: 75%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Text(
                '🔥 7 Match Winning Streak',
                style: TextStyle(
                  color: AppColors.warmOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, Color sportColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _buildGlassStatCard(
            context,
            'Win Rate',
            '72%',
            Icons.emoji_events_rounded,
            Colors.amber,
          ),
          _buildGlassStatCard(
            context,
            'Play Style',
            'All-Rounder',
            Icons.insights,
            AppColors.electricCyan,
          ),
          _buildGlassStatCard(
            context,
            'Total Games',
            '120 Played',
            Icons.sports_soccer,
            sportColor,
          ),
          _buildGlassStatCard(
            context,
            'Global Rank',
            '#128 Kochi',
            Icons.public_rounded,
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
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
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProofRow(BuildContext context, Color sportColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Friend circles overlap
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 36,
                child: Stack(
                  children: List.generate(
                    4,
                    (index) => Positioned(
                      left: index * 18.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundImage: AssetImage('assets/images/player_profile.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '48 Friends',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '12 online play-pals',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.sportsGreen.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Add/Find Friends floating scale button
          GestureDetector(
            onTapDown: (_) => setState(() => _isShareButtonHovered = true),
            onTapUp: (_) => setState(() => _isShareButtonHovered = false),
            onTapCancel: () => setState(() => _isShareButtonHovered = false),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing profile dynamic link...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: AnimatedScale(
              scale: _isShareButtonHovered ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [sportColor, sportColor.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: sportColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSection(BuildContext context, Color sportColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 12.0),
          child: Text(
            'Favorite Sports Interests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sportsList.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final sportItem = _sportsList[index];
              final isSelected = _selectedSport == sportItem['name'];
              final dynamicColor = _getSportColor(sportItem['name']);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSport = sportItem['name'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? dynamicColor
                        : AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? dynamicColor
                          : AppColors.outlineVariant.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: dynamicColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(
                        sportItem['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sportItem['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, Color sportColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabButton(0, 'Activity Log', sportColor),
              _buildTabButton(1, 'Achievements', sportColor),
              _buildTabButton(2, 'Streaks', sportColor),
            ],
          ),
        ),
        
        // Tab Content Layout
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildActiveTabContent(sportColor),
        ),
      ],
    );
  }

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
            color: isActive ? sportColor : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(Color sportColor) {
    switch (_activeActivityTab) {
      case 0:
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildTimelineActivity(
              title: 'Won Football Tournament',
              subtitle: 'Kochi Arena • 2 hours ago',
              xpReward: '+24 XP',
              sportEmoji: '⚽',
              sportColor: AppColors.sportsGreen,
            ),
            _buildTimelineActivity(
              title: 'Joined Cricket friendly match',
              subtitle: 'Royal Club Grounds • Yesterday',
              xpReward: '+10 XP',
              sportEmoji: '🏏',
              sportColor: Colors.blue,
            ),
            _buildTimelineActivity(
              title: 'Completed Tennis warm-up drill',
              subtitle: 'Town Court • 3 days ago',
              xpReward: '+15 XP',
              sportEmoji: '🎾',
              sportColor: Colors.lime.shade700,
            ),
          ],
        );
      case 1:
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _buildAchievementBadge('🏆', 'Tournament Champion', 'Gold Badge'),
            _buildAchievementBadge('⚡', 'Speed Demon', 'Paced 12 matches'),
            _buildAchievementBadge('🤝', 'Fair Play Star', 'Perfect rating'),
          ],
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔥 Weekly Play Streak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep playing to multiply your XP gains!',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Text(
                      'Streak x1.5',
                      style: TextStyle(color: sportColor, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStreakDay('M', true, sportColor),
                    _buildStreakDay('T', true, sportColor),
                    _buildStreakDay('W', true, sportColor),
                    _buildStreakDay('T', true, sportColor),
                    _buildStreakDay('F', true, sportColor),
                    _buildStreakDay('S', false, sportColor),
                    _buildStreakDay('S', false, sportColor),
                  ],
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimelineActivity({
    required String title,
    required String subtitle,
    required String xpReward,
    required String sportEmoji,
    required Color sportColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sportColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              sportEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sportsGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              xpReward,
              style: const TextStyle(
                color: AppColors.sportsGreen,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDay(String label, bool active, Color sportColor) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? sportColor : AppColors.surfaceDim.withValues(alpha: 0.3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: sportColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              active ? Icons.check : Icons.close,
              size: 14,
              color: active ? Colors.white : AppColors.outline.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(BuildContext context, Color sportColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildMenuTile(
            context,
            Icons.military_tech_outlined,
            'Dynamic Game Rules',
            'Read platform game guide',
            sportColor,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sportigo platform game guide coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuTile(
            context,
            Icons.history_toggle_off,
            'Platform Stats History',
            'Full tournament logs',
            sportColor,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tournament logs coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuTile(
            context,
            Icons.logout_rounded,
            'Sign Out',
            'Exit application cleanly',
            Colors.redAccent,
            () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDestructive ? Colors.red : AppColors.onSurface,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.outlineVariant,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
