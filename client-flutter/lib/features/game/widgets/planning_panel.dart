import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_actions.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/game/providers/game_controller.dart';
import 'package:star_cities/features/lobby/models/game.dart' as models;
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/shared/icon_widgets/ship_icon.dart';

class PlanningPanel extends ConsumerWidget {
  final models.Game game;
  final List<Piece> pieces;
  final bool flatten;
  final List<GameAction>? actionsOverride;

  const PlanningPanel({
    super.key,
    required this.game,
    required this.pieces,
    this.flatten = false,
    this.actionsOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(gamePlayersWithProfilesProvider(game.id));
    final currentUser = ref.watch(currentUserProvider);
    final uiState = ref.watch(gameplayUiProvider(game.id));
    
    // Use override actions if provided, otherwise local pending actions
    final List<GameAction> pendingActions = actionsOverride ?? ref.watch(pendingActionsProvider(game.id));
    final controller = ref.read(gameControllerProvider);

    return playersAsync.when(
      data: (players) {
        final currentPlayer = players.firstWhere(
          (p) => p.player.userId == currentUser?.id,
          orElse: () => players.first,
        );

        // Disable UI if we have an override (already submitted) or not in planning status
        final isReady = actionsOverride != null;
        final isPlanningMode = !isReady && game.status == models.GameStatus.planning;

        final trayPieces = pieces.where((p) => p.x == null && p.y == null && p.faction == currentPlayer.player.faction).toList();
        
        // Virtual State calculation (consistent with GameBoard)
        final virtualPieces = _calculateVirtualPieces(pieces, pendingActions);

        // Selection logic
        final selectedPiece = uiState.selectedPieceId != null
            ? virtualPieces.firstWhereOrNull((p) => p.id == uiState.selectedPieceId)
            : null;
            
        final placingPiece = uiState.placingPieceId != null
            ? trayPieces.firstWhereOrNull((p) => p.id == uiState.placingPieceId)
            : null;

        final actionButtons = [
          if (selectedPiece != null) ...[
            if (selectedPiece.type == PieceType.starCity) ...[
              if (!selectedPiece.isAnchored)
                _ActionButton(
                  onPressed: !isPlanningMode || pendingActions.any((a) => a is MoveAction && a.pieceId == selectedPiece.id)
                      ? null
                      : () {
                          ref.read(pendingActionsProvider(game.id).notifier).addOrReplaceAction(
                              AnchorAction(pieceId: selectedPiece.id, isAnchored: true));
                        },
                  icon: Icons.anchor,
                  tooltip: 'Anchor',
                ),
              if (selectedPiece.isAnchored)
                _ActionButton(
                  onPressed: !isPlanningMode || virtualPieces.any((p) => p.tetheredToId == selectedPiece.id) ||
                          pendingActions.any((a) => a is MoveAction && a.pieceId == selectedPiece.id)
                      ? null
                      : () {
                          ref.read(pendingActionsProvider(game.id).notifier).addOrReplaceAction(
                              AnchorAction(pieceId: selectedPiece.id, isAnchored: false));
                        },
                  icon: Icons.anchor_outlined,
                  tooltip: 'De-anchor',
                ),
            ],
            if (selectedPiece.type.requiresTether) ...[
              _ActionButton(
                onPressed: !isPlanningMode ? null : () {
                  ref.read(gameplayUiProvider(game.id).notifier).setRetethering(!uiState.isRetethering);
                },
                icon: Icons.link,
                tooltip: uiState.isRetethering ? 'Cancel Re-tether' : 'Re-tether',
                color: uiState.isRetethering ? theme.colorScheme.secondary : theme.colorScheme.onPrimary,
              ),
              if (selectedPiece.type == PieceType.eclipse)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _ActionButton(
                    onPressed: !isPlanningMode ? null : () {
                      if (pendingActions.any((a) => a is BombardAction && a.pieceId == selectedPiece.id)) {
                        ref.read(pendingActionsProvider(game.id).notifier).removeBombardment(selectedPiece.id);
                        ref.read(gameplayUiProvider(game.id).notifier).setBombarding(false);
                      } else {
                        ref.read(gameplayUiProvider(game.id).notifier).setBombarding(!uiState.isBombarding);
                      }
                    },
                    icon: Icons.gps_fixed,
                    tooltip: pendingActions.any((a) => a is BombardAction && a.pieceId == selectedPiece.id) 
                      ? 'Cancel Bombard' 
                      : (uiState.isBombarding ? 'Stop Selecting' : 'Bombard'),
                    color: (uiState.isBombarding || pendingActions.any((a) => a is BombardAction && a.pieceId == selectedPiece.id)) 
                      ? theme.colorScheme.secondary 
                      : theme.colorScheme.onPrimary,
                  ),
                ),
            ],
          ],
          // Placeholder to maintain height if no actions are available
          if (selectedPiece == null ||
              (selectedPiece.type != PieceType.starCity && !selectedPiece.type.requiresTether))
            const Opacity(
              opacity: 0.0,
              child: _ActionButton(
                onPressed: null,
                icon: Icons.circle,
                tooltip: '',
              ),
            ),
        ];

        final systemButtons = [
          TextButton(
            onPressed: !isPlanningMode ? null : () => controller.resetActions(game.id),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
              side: BorderSide(color: isPlanningMode ? theme.colorScheme.secondary : theme.disabledColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: !isPlanningMode ? null : () => controller.submitActions(game.id),
            child: const Text('Done'),
          ),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 370, maxWidth: 370),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Pieces Tray
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
                          onTap: !isPlanningMode ? null : () {
                            if (hasPlaceAction) {
                              // Cancel placement if already placed
                              ref.read(pendingActionsProvider(game.id).notifier).removePlacement(piece.id);
                              return;
                            }
                            if (isPlacing) {
                              ref.read(gameplayUiProvider(game.id).notifier).setPlacingPiece(null);
                            } else {
                              ref.read(gameplayUiProvider(game.id).notifier).setPlacingPiece(piece.id);
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

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Selection Status
                  Text(
                    isReady 
                        ? 'Turn actions submitted'
                        : (placingPiece != null
                            ? 'Placing: ${placingPiece.type.label}'
                            : (selectedPiece != null ? 'Selected: ${selectedPiece.type.label}' : 'No Selection')),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (placingPiece == null && selectedPiece == null || isReady) ? theme.disabledColor : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (flatten)
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: actionButtons,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: systemButtons,
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: actionButtons,
                    ),
                    const SizedBox(height: 12),
                    // System Buttons (Reset / Done)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: systemButtons,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => SizedBox(height: 150, child: Center(child: Text('Error: $e'))),
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
        // pieces stay put visually during planning
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

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color? color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = color ?? theme.colorScheme.onPrimary;

    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        disabledForegroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
