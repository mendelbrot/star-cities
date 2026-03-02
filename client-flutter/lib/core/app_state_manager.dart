import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppStateManager extends ChangeNotifier {
  AppStateManager(this._supabase) {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (session != null) {
          _userId = session.user.id;
          _subscribeToProfile();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _userId = null;
        _currentProfile = null;
        _profileSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  final SupabaseClient _supabase;
  late final StreamSubscription<AuthState> _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  String? _userId;
  Map<String, dynamic>? _currentProfile;

  Map<String, dynamic>? get currentProfile => _currentProfile;
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  bool get hasUsername => _currentProfile != null && _currentProfile!['username'] != null;

  void _subscribeToProfile() {
    if (_userId == null) return;

    _profileSubscription?.cancel();
    _profileSubscription = _supabase
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .listen((data) {
          if (data.isNotEmpty) {
            _currentProfile = data.first;
          } else {
            _currentProfile = null;
          }
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
