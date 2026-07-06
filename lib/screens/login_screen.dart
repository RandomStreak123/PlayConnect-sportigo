import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/custom_text_field.dart';
import '../data/repositories/auth_repository.dart';
import '../core/di/service_locator.dart';
import 'registration_screen.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  bool get _isForgotEnabled {
    final text = _usernameController.text.trim();
    if (text.isEmpty) return false;
    if (text.contains('@')) {
      // Basic email regex: must have chars before and after @, and a dot in domain
      return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text);
    }
    return text.length >= 3; // Username must be at least 3 characters
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to join your next match',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              CustomTextField(
                textFieldKey: const ValueKey('username_field'),
                label: 'Username',
                controller: _usernameController,
                hintText: 'Enter your username',
                icon: Icons.person_outline,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: AppSpacing.md + 4),
              CustomTextField(
                textFieldKey: const ValueKey('password_field'),
                label: 'Password',
                controller: _passwordController,
                hintText: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isForgotEnabled
                      ? () {
                          final input = Uri.encodeComponent(_usernameController.text.trim());
                          context.push('/reset-password?username_or_email=$input');
                        }
                      : null,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: _isForgotEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const ValueKey('signin_button'),
                  onPressed: _isLoading

                      ? null
                      : () async {
                          if (_usernameController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter username and password'),
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await getIt<AuthRepository>().logIn(
                                  username: _usernameController.text,
                                  password: _passwordController.text,
                                );
                          } catch (e) {
                             var errMsg = e.toString().replaceAll('Exception: ', '').trim();
                             if (errMsg.toLowerCase() == 'no user is exist' ||
                                 errMsg.toLowerCase() == 'invalid credential') {
                               // Keep exact error messages
                             } else if (errMsg.toLowerCase().contains('invalid credential') ||
                                 errMsg.toLowerCase().contains('invalid login details') ||
                                 errMsg.toLowerCase().contains('login failed')) {
                               errMsg = 'invalid credential';
                             }
                            messenger.showSnackBar(
                              SnackBar(content: Text(errMsg)),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(context).colorScheme.outlineVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const AppLoadingIndicator(color: Colors.white)
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: () {
                        _usernameController.clear();
                        _passwordController.clear();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
