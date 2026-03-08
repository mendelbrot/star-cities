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
        
        // Virtual State calculation (consistent with GameBoard)
        final virtualPieces = _calculateVirtualPieces(pieces, pendingActions);

        // Selection logic
        final selectedPiece = uiState.selectedPieceId != null
            ? virtualPieces.firstWhere((p) => p.id == uiState.selectedPieceId)
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
                    ] else if (selectedPiece != null) ...[
                      Text(
                        'Selected: ${selectedPiece.type.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (selectedPiece.type == PieceType.starCity) ...[
                             if (!selectedPiece.isAnchored)
                               ElevatedButton.icon(
                                 onPressed: () {
                                   ref.read(pendingActionsProvider(game.id).notifier).addAction(
                                     AnchorAction(pieceId: selectedPiece.id, isAnchored: true)
                                   );
                                 },
                                 icon: const Icon(Icons.anchor),
                                 label: const Text('Anchor'),
                               ),
                             if (selectedPiece.isAnchored)
                               ElevatedButton.icon(
                                 onPressed: virtualPieces.any((p) => p.tetheredToId == selectedPiece.id)
                                   ? null 
                                   : () {
                                       ref.read(pendingActionsProvider(game.id).notifier).addAction(
                                         AnchorAction(pieceId: selectedPiece.id, isAnchored: false)
                                       );
                                     },
                                 icon: const Icon(Icons.anchor_outlined),
                                 label: const Text('De-anchor'),
                               ),
                          ],
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

  // Duplicate calculation for consistency (ideally this should be in a provider)
  List<Piece> _calculateVirtualPieces(List<Piece> basePieces, List<GameAction> actions) {
    var virtual = List<Piece>.from(basePieces);
    for (var action in actions) {
      if (action is PlaceAction) {
        int idx = virtual.indexWhere((p) => p.id == action.trayPieceId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(x: action.target.x, y: action.target.y, tetheredToId: action.cityId);
        }
      } else if (action is MoveAction) {
        int idx = virtual.indexWhere((p) => p.id == action.pieceId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(x: action.to.x, y: action.to.y);
        }
      } else if (action is AnchorAction) {
        int idx = virtual.indexWhere((p) => p.id == action.pieceId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(isAnchored: action.isAnchored);
        }
      } else if (action is TetherAction) {
        int idx = virtual.indexWhere((p) => p.id == action.shipId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(tetheredToId: action.cityId);
        }
      }
    }
    return virtual;
  }
}
