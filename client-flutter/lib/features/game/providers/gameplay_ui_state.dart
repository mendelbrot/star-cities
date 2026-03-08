import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

class GameplayUiState {
  final String? selectedPieceId;
  final math.Point<int>? hoveredSquare;
  final int currentReplayStep;
  final bool isPanning;

  GameplayUiState({
    this.selectedPieceId,
    this.hoveredSquare,
    this.currentReplayStep = 1,
    this.isPanning = false,
  });

  GameplayUiState copyWith({
    String? selectedPieceId,
    math.Point<int>? hoveredSquare,
    int? currentReplayStep,
    bool? isPanning,
    bool clearSelectedPiece = false,
    bool clearHoveredSquare = false,
  }) {
    return GameplayUiState(
      selectedPieceId: clearSelectedPiece ? null : (selectedPieceId ?? this.selectedPieceId),
      hoveredSquare: clearHoveredSquare ? null : (hoveredSquare ?? this.hoveredSquare),
      currentReplayStep: currentReplayStep ?? this.currentReplayStep,
      isPanning: isPanning ?? this.isPanning,
    );
  }
}

class GameplayUiNotifier extends StateNotifier<GameplayUiState> {
  GameplayUiNotifier() : super(GameplayUiState());

  void selectPiece(String? id) {
    state = state.copyWith(selectedPieceId: id, clearSelectedPiece: id == null);
  }

  void hoverSquare(math.Point<int>? point) {
    state = state.copyWith(hoveredSquare: point, clearHoveredSquare: point == null);
  }

  void setReplayStep(int step) {
    state = state.copyWith(currentReplayStep: step);
  }

  void setPanning(bool panning) {
    state = state.copyWith(isPanning: panning);
  }
}

final gameplayUiProvider = StateNotifierProvider<GameplayUiNotifier, GameplayUiState>((ref) {
  return GameplayUiNotifier();
});
