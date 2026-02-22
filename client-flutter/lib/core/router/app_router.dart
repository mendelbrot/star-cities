import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:star_cities/features/auth/presentation/screens/sign_in/sign_in.dart';
import 'package:star_cities/features/lobby/presentation/screens/lobby.dart';
import 'package:star_cities/features/game/presentation/screens/game_board.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [Listenable] that notifies when the provided [Stream] emits a value.
/// Used to make GoRouter reactive to external state changes like Supabase auth.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  routes: [
    GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
    GoRoute(
      path: '/',
      builder: (context, state) => const LobbyPage(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameBoard(),
    ),
  ],
  redirect: (context, state) {
    final bool isGoingToLogin = state.uri.toString() == '/signin';
    final bool isAuthenticated =
        Supabase.instance.client.auth.currentUser != null;

    if (!isAuthenticated && !isGoingToLogin) {
      return '/signin'; // Redirect to sign in if not logged in
    }

    if (isAuthenticated && isGoingToLogin) {
      return '/'; // Redirect to home if already logged in but trying to sign in
    }

    return null; // No redirection needed
  },
);
