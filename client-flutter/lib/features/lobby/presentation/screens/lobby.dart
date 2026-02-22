import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is the lobby'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/game'),
              child: const Text('Enter Game (Mock)'),
            ),
          ],
        ),
      ),
    );
  }
}
