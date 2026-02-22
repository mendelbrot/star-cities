import 'package:flutter/material.dart';
import 'package:star_cities/features/auth/presentation/screens/sign_in/widgets/auth_header.dart';
import 'package:star_cities/features/auth/presentation/screens/sign_in/widgets/auth_error_message.dart';
import 'package:star_cities/features/auth/presentation/screens/sign_in/widgets/loading_button.dart';

class OTPStep extends StatelessWidget {
  final TextEditingController otpController;
  final String email;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;
  final bool isLoading;
  final String? errorMessage;

  const OTPStep({
    super.key,
    required this.otpController,
    required this.email,
    required this.onVerify,
    required this.onResend,
    required this.onChangeEmail,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: 'Enter Code',
          subtitle: 'We sent a 6-digit code to\n$email',
        ),
        const SizedBox(height: 48),
        TextFormField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onVerify(),
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(
            labelText: 'Code',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          onPressed: onVerify,
          label: 'Verify Code',
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'More Options',
            onSelected: (value) {
              if (value == 'change_email') {
                onChangeEmail();
              } else if (value == 'resend_code') {
                onResend();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'resend_code',
                child: Text('Resend Code'),
              ),
              const PopupMenuItem(
                value: 'change_email',
                child: Text('Change Email'),
              ),
            ],
          ),
        ),
        AuthErrorMessage(message: errorMessage),
      ],
    );
  }
}
