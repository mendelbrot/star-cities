import 'package:flutter/material.dart';
import 'package:star_cities/features/auth/providers/sign_in_controller.dart';
import 'package:star_cities/features/auth/widgets/sign_in_page_widgets.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';
import 'package:star_cities/shared/widgets/ship_banner.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _controller = SignInPageController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode([String? _]) async {
    if (_controller.isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _controller.sendOTP(_emailController.text);
  }

  Future<void> _verifyCode([String? _]) async {
    if (_controller.isLoading) {
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the code')));
      return;
    }

    final success = await _controller.verifyOTP(
      _emailController.text,
      _otpController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Invalid code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: ShipBanner(shipCount: 9, spacing: 8),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'STAR CITIES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const SizedBox(
                          height: 200,
                          child: ShipIcon(
                            type: PieceType.starCity,
                            faction: Faction.magenta,
                            isAnchored: false,
                            size: null,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Form(
                          key: _formKey,
                          child: ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) {
                              if (!_controller.codeSent) {
                                return EmailStep(
                                  emailController: _emailController,
                                  onSend: _sendCode,
                                  isLoading: _controller.isLoading,
                                  errorMessage: _controller.errorMessage,
                                );
                              }

                              return OTPStep(
                                otpController: _otpController,
                                email: _emailController.text,
                                onVerify: _verifyCode,
                                onResend: _sendCode,
                                onChangeEmail: () {
                                  _otpController.clear();
                                  _controller.reset();
                                },
                                isLoading: _controller.isLoading,
                                errorMessage: _errorMessage(
                                  _controller.errorMessage,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _errorMessage(String? message) {
    if (message == null) return null;
    return message;
  }
}
