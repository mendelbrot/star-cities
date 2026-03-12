import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/lobby/models/game.dart';

class GameplayUiState {
  final String? selectedPieceId;
  final String? placingPieceId; // Current piece being placed from tray
  final String? selectedCityId;  // Target city for tethering during placement
  final bool isBombarding;      // Whether we are currently selecting a target for bombardment
  final bool isRetethering;     // Whether we are currently selecting a target for re-tethering
  final math.Point<int>? hoveredSquare;
  final int currentReplayStep;
  final bool isPanning;
  final GameEvent? selectedEvent;

  GameplayUiState({
    this.selectedPieceId,
    this.placingPieceId,
    this.selectedCityId,
    this.isBombarding = false,
    this.isRetethering = false,
    this.hoveredSquare,
    this.currentReplayStep = 1,
    this.isPanning = false,
    this.selectedEvent,
  });

  GameplayUiState copyWith({
    String? selectedPieceId,
    String? placingPieceId,
    String? selectedCityId,
    bool? isBombarding,
    bool? isRetethering,
    math.Point<int>? hoveredSquare,
    int? currentReplayStep,
    bool? isPanning,
    GameEvent? selectedEvent,
    bool clearSelectedPiece = false,
    bool clearPlacingPiece = false,
    bool clearSelectedCity = false,
    bool clearHoveredSquare = false,
    bool clearSelectedEvent = false,
  }) {
    return GameplayUiState(
      selectedPieceId: clearSelectedPiece ? null : (selectedPieceId ?? this.selectedPieceId),
      placingPieceId: clearPlacingPiece ? null : (placingPieceId ?? this.placingPieceId),
      selectedCityId: clearSelectedCity ? null : (selectedCityId ?? this.selectedCityId),
      isBombarding: isBombarding ?? this.isBombarding,
      isRetethering: isRetethering ?? this.isRetethering,
      hoveredSquare: clearHoveredSquare ? null : (hoveredSquare ?? this.hoveredSquare),
      currentReplayStep: currentReplayStep ?? this.currentReplayStep,
      isPanning: isPanning ?? this.isPanning,
      selectedEvent: clearSelectedEvent ? null : (selectedEvent ?? this.selectedEvent),
    );
  }
}

class GameplayUiNotifier extends StateNotifier<GameplayUiState> {
  GameplayUiNotifier() : super(GameplayUiState());

  void selectPiece(String? id) {
    state = state.copyWith(
      selectedPieceId: id, 
      clearSelectedPiece: id == null,
      clearPlacingPiece: true, // Reset placement if selecting board piece
      clearSelectedCity: true,
      isBombarding: false,
      isRetethering: false,
    );
  }

  void setPlacingPiece(String? id) {
    state = state.copyWith(
      placingPieceId: id,
      clearPlacingPiece: id == null,
      clearSelectedPiece: true, // Reset board selection if placing
      clearSelectedCity: true,
      isBombarding: false,
      isRetethering: false,
    );
  }

  void setSelectedCity(String? id) {
    state = state.copyWith(selectedCityId: id, clearSelectedCity: id == null);
  }

  void setBombarding(bool bombarding) {
    state = state.copyWith(isBombarding: bombarding, isRetethering: false);
  }

  void setRetethering(bool retethering) {
    state = state.copyWith(isRetethering: retethering, isBombarding: false);
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

  void selectEvent(GameEvent? event) {
    state = state.copyWith(selectedEvent: event, clearSelectedEvent: event == null);
  }

  void resetPlacement() {
    state = state.copyWith(clearPlacingPiece: true, clearSelectedCity: true);
  }

  void clearSelection() {
    state = state.copyWith(
      clearSelectedPiece: true,
      clearPlacingPiece: true,
      clearSelectedCity: true,
      isBombarding: false,
      isRetethering: false,
    );
  }
}

final gameplayUiProvider = StateNotifierProvider.autoDispose.family<GameplayUiNotifier, GameplayUiState, String>((ref, gameId) {
  final notifier = GameplayUiNotifier();

  // Reset selection when game status is not planning
  ref.listen(gameProvider(gameId), (previous, next) {
    next.whenData((game) {
      if (game?.status != GameStatus.planning) {
        notifier.clearSelection();
      }
    });
  });

  return notifier;
});

