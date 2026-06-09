import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../core/constants/colors.dart';
import '../data/repositories/auth_repository.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleSignUp() async {
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().register(
            name: _nameController.text,
            username: _usernameController.text,
            password: _passwordController.text,
            gender: _selectedGender,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in.'),
            backgroundColor: AppColors.sportsGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Join the Sportigo community',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl + 4),
              _buildTextField(
                label: 'Full Name',
                controller: _nameController,
                hintText: 'Enter your full name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppSpacing.md + 4),
              _buildTextField(
                label: 'Username',
                controller: _usernameController,
                hintText: 'Choose a username',
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: AppSpacing.md + 4),
              _buildTextField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Create a password',
                icon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildGenderSelector(),
              const SizedBox(height: AppSpacing.xl + 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const ValueKey('signup_button'),
                  onPressed: _isLoading ? null : _handleSignUp,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const AppLoadingIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender Identity (Optional)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildGenderCard('male', 'Male', Icons.male, Colors.blue),
            const SizedBox(width: AppSpacing.sm),
            _buildGenderCard('female', 'Female', Icons.female, Colors.pink),
            const SizedBox(width: AppSpacing.sm),
            _buildGenderCard('other', 'Other', Icons.transgender, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String value, String label, IconData icon, Color activeColor) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected 
                ? activeColor.withValues(alpha: 0.15) 
                : Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: ValueKey('${label.toLowerCase().replaceAll(' ', '_')}_field'),
          controller: controller,

          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.outline),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
