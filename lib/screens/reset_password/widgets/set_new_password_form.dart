import 'package:flutter/material.dart';
import '../../../../widgets/app_loading_indicator.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/feedback_banner.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';


class SetNewPasswordForm extends StatefulWidget {
  final String token;
  final String email;

  const SetNewPasswordForm({required this.token, required this.email, super.key});

  @override
  State<SetNewPasswordForm> createState() => _SetNewPasswordFormState();
}

class _SetNewPasswordFormState extends State<SetNewPasswordForm> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in both password fields';
        _successMessage = null;
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
        _successMessage = null;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await getIt<AuthRepository>().resetPassword(
        token: widget.token,
        email: widget.email,
        password: password,
        passwordConfirmation: confirm,
      );
      setState(() {
        _successMessage = message;
      });
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception: ', '').trim();
      setState(() {
        _errorMessage = errMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedbackBanner(
          successMessage: _successMessage,
          errorMessage: _errorMessage,
        ),
        if (_successMessage == null) ...[
          CustomTextField(
            textFieldKey: const ValueKey('new_password_field'),
            label: 'New Password',
            controller: _passwordController,
            hintText: 'Min 8 characters',
            icon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onToggleVisibility: () {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            },
          ),
          const SizedBox(height: AppSpacing.md + 4),
          CustomTextField(
            textFieldKey: const ValueKey('confirm_password_field'),
            label: 'Confirm Password',
            controller: _confirmController,
            hintText: 'Confirm new password',
            icon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isConfirmVisible,
            onToggleVisibility: () {
              setState(() => _isConfirmVisible = !_isConfirmVisible);
            },
          ),
          const SizedBox(height: AppSpacing.xl + 4),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              key: const ValueKey('reset_password_button'),
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Theme.of(context).colorScheme.outlineVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const AppLoadingIndicator(color: Colors.white)
                  : const Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
