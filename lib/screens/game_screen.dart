import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/game_controller.dart';
import '../controllers/progress_controller.dart';
import '../models/nonogram_state.dart';
import '../models/puzzle_pack.dart';
import '../utils/app_theme.dart';
import '../utils/puzzle_registry.dart';
import '../widgets/nonogram_grid_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String puzzleId;

  const GameScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showComplete = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Load the puzzle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final puzzle = PuzzleRegistry.findById(widget.puzzleId);
      if (puzzle != null) {
        ref.read(gameControllerProvider.notifier).loadPuzzle(puzzle);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_showComplete) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  String get _timerText {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double _completionProgress(NonogramState state) {
    int satisfiedRows = 0;
    for (int r = 0; r < state.puzzle.gridSize; r++) {
      if (state.isRowSatisfied(r)) satisfiedRows++;
    }
    return satisfiedRows / state.puzzle.gridSize;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Detect completion
    ref.listen(gameControllerProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        HapticFeedback.heavyImpact();
        _timer?.cancel();
        // Save result
        final result = PuzzleResult(
          puzzleId: next.puzzle.id,
          starsEarned: _calculateStars(next),
          timeSeconds: _elapsedSeconds,
          score: _calculateScore(next),
          mistakes: next.mistakes,
        );
        ref.read(progressProvider.notifier).completePuzzle(
          result,
          gridSize: next.puzzle.gridSize,
        );
        setState(() => _showComplete = true);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress bar
                _buildProgressBar(state),
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
                        onCellTap: (row, col) => controller.tapCell(row, col),
                      ),
                    ),
                  ),
                ),
                // Mode toggle
                _buildModeToggle(state, controller),
                const SizedBox(height: 16),
              ],
            ),
            // Completion overlay
            if (_showComplete) _buildCompletionOverlay(state, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(NonogramState state) {
    final progress = _completionProgress(state);
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1850),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD84B), Color(0xFFFF9500)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(NonogramState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${state.puzzle.packId.toUpperCase()} \u2022 ${state.puzzle.title}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            '${state.puzzle.gridSize}x${state.puzzle.gridSize}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF9999CC)),
          const SizedBox(width: 4),
          Text(
            _timerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 16),
          // Lives
          Text(
            List.generate(
                    3, (i) => i < state.livesRemaining ? '\u2764' : '\u2661')
                .join(),
            style: TextStyle(
              fontSize: 14,
              color: state.livesRemaining > 0
                  ? const Color(0xFFFF4F7B)
                  : Colors.grey,
            ),
          ),
          const Spacer(),
          // Rows completed
          Text(
            '${_satisfiedRowCount(state)}/${state.puzzle.gridSize} rows',
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  int _satisfiedRowCount(NonogramState state) {
    int count = 0;
    for (int r = 0; r < state.puzzle.gridSize; r++) {
      if (state.isRowSatisfied(r)) count++;
    }
    return count;
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
          _modeButton('FILL', InputMode.fill, state.inputMode, controller),
          _modeButton('MARK', InputMode.mark, state.inputMode, controller),
        ],
      ),
    );
  }

  Widget _modeButton(String label, InputMode mode, InputMode current,
      GameController controller) {
    final active = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!active) {
            HapticFeedback.selectionClick();
            controller.toggleMode();
          }
        },
        child: Container(
          decoration: active
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE066), Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: active ? const Color(0xFF1a0a00) : const Color(0xFF9999CC),
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay(NonogramState state, GameController controller) {
    final score = _calculateScore(state);
    final stars = _calculateStars(state);

    return Container(
      color: const Color(0xFF0F0C29).withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1464), Color(0xFF12103a)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'PUZZLE SOLVED!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00E676),
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.puzzle.title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF9999CC),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final filled = i < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star_rounded,
                      size: 40,
                      color: filled
                          ? const Color(0xFFFFD84B)
                          : const Color(0xFF2a2a5a),
                      shadows: filled
                          ? [
                              Shadow(
                                color: const Color(0xFFFFD84B)
                                    .withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem('TIME', _timerText),
                  _statItem('ERRORS', '${state.mistakes}'),
                  _statItem('SCORE', '$score'),
                ],
              ),
              const SizedBox(height: 20),
              // Next puzzle button
              GestureDetector(
                onTap: () {
                  final next = PuzzleRegistry.nextPuzzle(state.puzzle.id);
                  if (next != null) {
                    controller.loadPuzzle(next);
                    _startTimer();
                    setState(() => _showComplete = false);
                  } else {
                    context.pop(); // Back to pack select
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE066), Color(0xFFFFD84B), Color(0xFFFF9500)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NEXT PUZZLE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1a0a00),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Color(0xFF1a0a00)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9999CC),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  int _calculateScore(NonogramState state) {
    final base = state.puzzle.gridSize * state.puzzle.gridSize * 10;
    final errorPenalty = state.mistakes * 50;
    final timeBonus =
        (state.puzzle.parTimeSeconds - _elapsedSeconds).clamp(0, 999) * 5;
    final noErrorBonus = state.mistakes == 0 ? 200 : 0;
    return (base - errorPenalty + timeBonus + noErrorBonus).clamp(0, 99999);
  }

  int _calculateStars(NonogramState state) {
    final underPar = _elapsedSeconds <= state.puzzle.parTimeSeconds;
    final noErrors = state.mistakes == 0;
    if (noErrors && underPar) return 3;
    if (noErrors || underPar) return 2;
    return 1;
  }
}
