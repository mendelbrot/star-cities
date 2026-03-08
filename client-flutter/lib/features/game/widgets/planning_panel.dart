import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_actions.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/game/providers/game_controller.dart';
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
    final pendingActions = ref.watch(pendingActionsProvider(game.id));
    final controller = ref.read(gameControllerProvider);

    return playersAsync.when(
      data: (players) {
        final currentPlayer = players.firstWhere(
          (p) => p.player.userId == currentUser?.id,
          orElse: () => players.first,
        );

        final trayPieces = pieces.where((p) => p.x == null && p.y == null && p.faction == currentPlayer.player.faction).toList();
        
        // Piece selection logic
        final selectedPiece = uiState.selectedPieceId != null
            ? pieces.firstWhere((p) => p.id == uiState.selectedPieceId)
            : null;
            
        final placingPiece = uiState.placingPieceId != null
            ? trayPieces.firstWhere((p) => p.id == uiState.placingPieceId)
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
                    final isPlacing = uiState.placingPieceId == piece.id;
                    final hasPlaceAction = pendingActions.any((a) => a is PlaceAction && a.trayPieceId == piece.id);
                    
                    return GestureDetector(
                      onTap: hasPlaceAction ? null : () {
                        if (isPlacing) {
                          ref.read(gameplayUiProvider.notifier).setPlacingPiece(null);
                        } else {
                          ref.read(gameplayUiProvider.notifier).setPlacingPiece(piece.id);
                        }
                      },
                      child: Opacity(
                        opacity: hasPlaceAction ? 0.3 : 1.0,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isPlacing ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: isPlacing ? theme.colorScheme.primary : Colors.transparent,
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
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Contextual Instruction or Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (placingPiece != null) ...[
                      Text(
                        'Placing: ${placingPiece.type.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (placingPiece.type.requiresTether && uiState.selectedCityId == null)
                        const Text('Step 2: Select an anchored Star City to tether to.')
                      else if (placingPiece.type.requiresTether && uiState.selectedCityId != null)
                        const Text('Step 3: Select an empty square adjacent to the city.')
                      else
                        const Text('Step 2: Select an empty square adjacent to any of your cities.'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.read(gameplayUiProvider.notifier).resetPlacement(),
                        child: const Text('Cancel Placement'),
                      ),
                    ] else if (selectedPiece != null) ...[
                      Text(
                        'Selected: ${selectedPiece.type.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (selectedPiece.type == PieceType.starCity)
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(pendingActionsProvider(game.id).notifier).addAction(
                                  AnchorAction(pieceId: selectedPiece.id, isAnchored: !selectedPiece.isAnchored)
                                );
                              },
                              icon: Icon(selectedPiece.isAnchored ? Icons.anchor : Icons.anchor_outlined),
                              label: Text(selectedPiece.isAnchored ? 'De-anchor' : 'Anchor'),
                            ),
                          if (selectedPiece.type.requiresTether) ...[
                            ElevatedButton.icon(
                              onPressed: () {}, // TODO: Implement Re-tether flow
                              icon: const Icon(Icons.link),
                              label: const Text('Re-tether'),
                            ),
                            if (selectedPiece.type == PieceType.eclipse)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {}, // TODO: Implement Bombard flow
                                  icon: const Icon(Icons.gps_fixed),
                                  label: const Text('Bombard'),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ] else
                      const Text('Select a piece from the tray or the board to plan your turn.'),
                  ],
                ),
              ),

              // Reset / Done Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => controller.resetActions(game.id),
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => controller.submitActions(game.id),
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
