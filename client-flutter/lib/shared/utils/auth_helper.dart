import 'package:supabase_flutter/supabase_flutter.dart';

class AuthHelper {
  /// Returns the current Supabase user, if any.
  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Returns true if there is an active session.
  static bool get isAuthenticated => currentUser != null;

  /// Returns the email of the current user, if any.
  static String? get userEmail => currentUser?.email;

  /// Signs out the current user.
  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
