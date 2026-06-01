import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/game_controller.dart';
import '../models/nonogram_state.dart';
import '../utils/sample_puzzles.dart';
import '../widgets/nonogram_grid_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final Stopwatch _stopwatch = Stopwatch()..start();

  String get _elapsedFormatted {
    final seconds = _stopwatch.elapsed.inSeconds;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(state),
            // HUD
            _buildHUD(state),
            const SizedBox(height: 8),
            // Grid
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: NonogramGridWidget(
                    state: state,
                    onCellTap: (row, col) {
                      HapticFeedback.lightImpact();
                      controller.tapCell(row, col);
                    },
                  ),
                ),
              ),
            ),
            // Mode toggle
            _buildModeToggle(state, controller),
            const SizedBox(height: 8),
            // Puzzle selector (prototype only)
            _buildPuzzleSelector(controller),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(NonogramState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${state.puzzle.packId.toUpperCase()} • ${state.puzzle.title}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (state.isComplete)
            const Text(
              'SOLVED!',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHUD(NonogramState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Timer
          Text(
            _elapsedFormatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          // Lives
          Text(
            List.generate(3, (i) => i < state.livesRemaining ? '♥' : '♡').join(),
            style: TextStyle(
              fontSize: 14,
              color: state.livesRemaining > 0
                  ? const Color(0xFFFF4F7B)
                  : Colors.grey,
            ),
          ),
          const Spacer(),
          // Mistakes
          Text(
            'Errors: ${state.mistakes}',
            style: const TextStyle(
              color: Color(0xFF9999CC),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(NonogramState state, GameController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (state.inputMode != InputMode.fill) controller.toggleMode();
              },
              child: Container(
                decoration: state.inputMode == InputMode.fill
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE066), Color(0xFFFF9500)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  'FILL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: state.inputMode == InputMode.fill
                        ? const Color(0xFF1a0a00)
                        : const Color(0xFF9999CC),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (state.inputMode != InputMode.mark) controller.toggleMode();
              },
              child: Container(
                decoration: state.inputMode == InputMode.mark
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE066), Color(0xFFFF9500)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  'MARK',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: state.inputMode == InputMode.mark
                        ? const Color(0xFF1a0a00)
                        : const Color(0xFF9999CC),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleSelector(GameController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final puzzle in SamplePuzzles.all)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                controller.loadPuzzle(puzzle);
                _stopwatch.reset();
                _stopwatch.start();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Text(
                  '${puzzle.title} ${puzzle.gridSize}x${puzzle.gridSize}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
