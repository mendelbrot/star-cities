import 'package:flutter/material.dart';
import 'package:star_cities/features/auth/widgets/auth_header.dart';
import 'package:star_cities/features/auth/widgets/auth_error_message.dart';
import 'package:star_cities/features/auth/widgets/loading_button.dart';

class EmailStep extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSend;
  final bool isLoading;
  final String? errorMessage;

  const EmailStep({
    super.key,
    required this.emailController,
    required this.onSend,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(title: 'Sign In / Sign Up'),
        const SizedBox(height: 48),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (_) => onSend(),
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        LoadingButton(
          onPressed: onSend,
          label: 'Send Code',
          isLoading: isLoading,
        ),
        AuthErrorMessage(message: errorMessage),
      ],
    );
  }
}
