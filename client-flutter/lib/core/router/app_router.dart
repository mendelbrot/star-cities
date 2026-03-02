import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:star_cities/core/app_state_manager.dart';
import 'package:star_cities/features/auth/presentation/screens/sign_in/sign_in.dart';
import 'package:star_cities/features/lobby/presentation/screens/lobby.dart';
import 'package:star_cities/features/game/presentation/screens/game_board.dart';

// Placeholder for the profile screen
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile Setup')));
}

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
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const LobbyPage(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          // ignore: unused_local_variable
          final gameId = state.pathParameters['id'];
          return const GameBoard(); // GameBoard will need the ID eventually
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

      // 3. If authenticated and has username, don't allow signin or profile pages
      if (isSigningIn || isSettingProfile) {
        return '/';
      }

      return null;
    },
  );
}
