import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/lobby/models/game.dart' as models;
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';

class PlanningPanel extends ConsumerWidget {
  final models.Game game;
  final List<Piece> pieces;

  const PlanningPanel({
    super.key,
    required this.game,
    required this.pieces,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(gamePlayersWithProfilesProvider(game.id));
    final currentUser = ref.watch(currentUserProvider);
    final uiState = ref.watch(gameplayUiProvider);

    return playersAsync.when(
      data: (players) {
        final currentPlayer = players.firstWhere(
          (p) => p.player.userId == currentUser?.id,
          orElse: () => players.first,
        );

        final trayPieces = pieces.where((p) => p.x == null && p.y == null && p.faction == currentPlayer.player.faction).toList();
        final selectedPiece = uiState.selectedPieceId != null
            ? pieces.firstWhere((p) => p.id == uiState.selectedPieceId)
            : null;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pieces Tray
              const Text('Pieces Tray', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trayPieces.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final piece = trayPieces[index];
                    final isSelected = uiState.selectedPieceId == piece.id;
                    return GestureDetector(
                      onTap: () => ref.read(gameplayUiProvider.notifier).selectPiece(isSelected ? null : piece.id),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: ShipIcon(
                            type: piece.type,
                            faction: piece.faction,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Selected Piece Contextual Actions
              if (selectedPiece != null) ...[
                Text(
                  'Selected: ${selectedPiece.type.label}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (selectedPiece.type == PieceType.starCity)
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(selectedPiece.isAnchored ? Icons.anchor : Icons.anchor_outlined),
                        label: Text(selectedPiece.isAnchored ? 'De-anchor' : 'Anchor'),
                      ),
                    if (selectedPiece.type.requiresTether) ...[
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.link),
                        label: const Text('Re-tether'),
                      ),
                      if (selectedPiece.type == PieceType.eclipse)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text('Bombard'),
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Reset / Done Buttons
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading players: $e')),
    );
  }
}
