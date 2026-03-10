import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';

class ReplayPanel extends ConsumerWidget {
  const ReplayPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(gameplayUiProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'REPLAY STEPS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final step = index + 1;
              final isSelected = uiState.currentReplayStep == step;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => ref.read(gameplayUiProvider.notifier).setReplayStep(step),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.black,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '$step',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          _getStepLabel(uiState.currentReplayStep),
        ],
      ),
    );
  }

  Widget _getStepLabel(int step) {
    final labels = [
      'Structural (Place/Tether/Anchor)',
      'Bombardment',
      'Primary Movement',
      'Combat (Battle/Collision)',
      'Resolution Movement',
      'Lifecycle (Acquisitions/Eliminations)',
      'Conclusion',
    ];

    return Text(
      labels[step - 1].toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}
