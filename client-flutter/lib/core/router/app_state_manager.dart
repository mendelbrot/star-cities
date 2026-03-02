import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages the application-wide authentication state for the router.
/// It uses the Supabase Auth user metadata to check for a username, 
/// which avoids additional database round-trips for the initial redirect check.
class AppStateManager extends ChangeNotifier {
  AppStateManager(this._supabase) {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      // Notify the router when auth state changes (login, logout, metadata updates)
      notifyListeners();
    });
  }

  final SupabaseClient _supabase;
  late final StreamSubscription<AuthState> _authSubscription;

  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Returns true if the user's auth metadata contains a 'username'.
  bool get hasUsername {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    
    final metadata = user.userMetadata;
    return metadata != null && 
           metadata.containsKey('username') && 
           metadata['username'] != null && 
           (metadata['username'] as String).isNotEmpty;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
