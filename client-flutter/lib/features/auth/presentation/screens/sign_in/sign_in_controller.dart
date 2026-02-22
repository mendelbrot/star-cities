import 'package:star_cities/shared/utils/get_error_message.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInPageController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _codeSent = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get codeSent => _codeSent;

  Future<void> sendOTP(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email.trim());
      _codeSent = true;
    } catch (e) {
      _errorMessage = getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyOTP(String email, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool isOTPVerified = false;

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.email,
      );
      isOTPVerified = true;
    } catch (e) {
      _errorMessage = getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
    return isOTPVerified;
  }

  void reset() {
    _codeSent = false;
    _errorMessage = null;
    notifyListeners();
  }
}
