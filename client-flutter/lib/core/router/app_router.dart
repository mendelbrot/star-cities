import 'package:go_router/go_router.dart';
import 'app_state_manager.dart';
import 'package:star_cities/features/auth/screens/sign_in.dart';
import 'package:star_cities/features/profile/screens/profile_setup.dart';
import 'package:star_cities/features/lobby/screens/lobby.dart';
import 'package:star_cities/features/lobby/screens/game_setup.dart';
import 'package:star_cities/features/game/screens/game_screen.dart';

GoRouter createRouter(AppStateManager appStateManager) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appStateManager,
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Lobby(),
      ),
      GoRoute(
        path: '/game-setup',
        builder: (context, state) => const GameSetup(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final gameId = state.pathParameters['id']!;
          return GameScreen(gameId: gameId);
        },
      ),
    ],
    redirect: (context, state) {
      final bool isAuthenticated = appStateManager.isAuthenticated;
      final bool hasUsername = appStateManager.hasUsername;
      
      final bool isSigningIn = state.uri.toString() == '/signin';
      final bool isSettingProfile = state.uri.toString() == '/profile';

      // 1. If not authenticated, force to signin
      if (!isAuthenticated) {
        return isSigningIn ? null : '/signin';
      }

      // 2. If authenticated but no username, force to profile
      if (!hasUsername) {
        return isSettingProfile ? null : '/profile';
      }

      // 3. If authenticated and has username, don't allow signin page
      if (isSigningIn) {
        return '/';
      }

      return null;
    },
  );
}
