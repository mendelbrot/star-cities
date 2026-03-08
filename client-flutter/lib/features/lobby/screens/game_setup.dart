import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';

class GameSetup extends StatefulWidget {
  const GameSetup({super.key});

  @override
  State<GameSetup> createState() => _GameSetupState();
}

class _GameSetupState extends State<GameSetup> {
  final _supabase = Supabase.instance.client;
  int _playerCount = 4;
  int _starCountToWin = 3;
  bool _isLoading = false;

  Future<void> _createGame() async {
    setState(() => _isLoading = true);
    
    // Show instant loading overlay
    final overlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: const Center(child: GridLoadingIndicator(size: 60)),
      ),
    );
    Overlay.of(context).insert(overlay);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final gameParameters = {
        "grid_size": 9,
        "star_count": 6,
        "star_count_to_win": _starCountToWin,
        "max_ships_per_city": 5,
        "starting_ships": ["NEUTRINO", "NEUTRINO", "PARALLAX", "ECLIPSE"]
      };

      final gameData = await _supabase.from('games').insert({
        'player_count': _playerCount,
        'game_parameters': gameParameters,
      }).select().single();

      final gameId = gameData['id'];

      await _supabase.from('players').insert({
        'game_id': gameId,
        'user_id': user.id,
        'faction': Faction.random().value,
      });

      if (mounted) {
        context.go('/game/$gameId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      overlay.remove();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: const Text('New Game'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('PLAYERS: $_playerCount'),
                Slider(
                  value: _playerCount.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: _playerCount.toString(),
                  onChanged: (value) {
                    setState(() => _playerCount = value.round());
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('STARS TO WIN: $_starCountToWin'),
                Slider(
                  value: _starCountToWin.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: _starCountToWin.toString(),
                  onChanged: (value) {
                    setState(() => _starCountToWin = value.round());
                  },
                ),
                const SizedBox(height: 64),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createGame,
                  child: const Text('CREATE GAME'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
