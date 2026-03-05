import 'package:go_router/go_router.dart';
import 'app_state_manager.dart';
import 'package:star_cities/features/auth/presentation/screens/sign_in/sign_in.dart';
import 'package:star_cities/features/profile/presentation/screens/profile_setup.dart';
import 'package:star_cities/features/lobby/presentation/screens/lobby.dart';
import 'package:star_cities/features/game/presentation/screens/game_room.dart';

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
        builder: (context, state) => const LobbyPage(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final gameId = state.pathParameters['id']!;
          return GameRoom(gameId: gameId);
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
