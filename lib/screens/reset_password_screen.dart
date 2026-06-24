import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'reset_password/widgets/request_reset_link_form.dart';
import 'reset_password/widgets/set_new_password_form.dart';
import '../core/theme/app_spacing.dart';

class ResetPasswordScreen extends StatelessWidget {
  /// When [token] and [email] are non-null the screen shows the
  /// "set new password" form (Mode B). Otherwise it shows the
  /// "send me a reset link" form (Mode A).
  final String? token;
  final String? email;
  final String? usernameOrEmail;

  const ResetPasswordScreen({
    super.key,
    this.token,
    this.email,
    this.usernameOrEmail,
  });

  bool get _isModB => token != null && email != null;

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
                _isModB ? 'Set New Password' : 'Reset Password',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _isModB
                    ? 'Enter your new password below'
                    : "Enter your username or email address and we'll send you a link to reset your password.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Renders Mode A or Mode B form
              if (!_isModB)
                RequestResetLinkForm(usernameOrEmail: usernameOrEmail)
              else
                SetNewPasswordForm(token: token!, email: email!),

              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


