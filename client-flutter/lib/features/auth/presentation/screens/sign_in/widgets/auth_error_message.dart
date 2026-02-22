import 'package:flutter/material.dart';

class AuthErrorMessage extends StatelessWidget {
  final String? message;

  const AuthErrorMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        message!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
