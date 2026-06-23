import 'package:flutter/material.dart';
import '../../profile_settings_screen.dart';

class ProfileCustomAppBar extends StatelessWidget {
  final bool isCurrentUser;

  const ProfileCustomAppBar({
    super.key,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isCurrentUser) const BackButton(),
          Expanded(
            child: Text(
              'Player Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: isCurrentUser ? TextAlign.start : TextAlign.center,
            ),
          ),
          if (isCurrentUser)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
            )
          else
            const SizedBox(width: 48), // Balance for BackButton
        ],
      ),
    );
  }
}
