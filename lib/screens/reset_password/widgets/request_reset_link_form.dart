import 'package:flutter/material.dart';
import '../../../../widgets/app_loading_indicator.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/feedback_banner.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';


class RequestResetLinkForm extends StatefulWidget {
  final String? usernameOrEmail;

  const RequestResetLinkForm({super.key, this.usernameOrEmail});

  @override
  State<RequestResetLinkForm> createState() => _RequestResetLinkFormState();
}

class _RequestResetLinkFormState extends State<RequestResetLinkForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.usernameOrEmail != null) {
      final text = widget.usernameOrEmail!.trim();
      if (text.contains('@')) {
        _emailController.text = text;
      } else {
        _usernameController.text = text;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (username.isEmpty || email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your username and email address';
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
      final message = await getIt<AuthRepository>().sendResetLink(
        username: username,
        email: email,
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
            textFieldKey: const ValueKey('reset_username_field'),
            label: 'Username',
            controller: _usernameController,
            hintText: 'Enter username',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            textFieldKey: const ValueKey('reset_email_field'),
            label: 'Email Address',
            controller: _emailController,
            hintText: 'Enter email address',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.xl + 4),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              key: const ValueKey('send_reset_link_button'),
              onPressed: _isLoading ? null : _handleSendResetLink,
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
                      'Send Reset Link',
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
