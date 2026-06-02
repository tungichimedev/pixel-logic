import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/achievements_controller.dart';
import '../controllers/daily_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/progress_controller.dart';
import '../models/nonogram_state.dart';
import '../models/puzzle_pack.dart';
import '../utils/app_theme.dart';
import '../utils/puzzle_registry.dart';
import '../widgets/nonogram_grid_widget.dart';
import '../widgets/pixel_art_reveal.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String puzzleId;

  const GameScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showComplete = false;
  bool _showZeroLives = false;
  late final List<AnimationController> _starControllers;
  late final List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(3, (i) => AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    ));
    _starAnimations = _starControllers.map((c) =>
      CurvedAnimation(parent: c, curve: Curves.elasticOut),
    ).toList();
    _startTimer();
    // Load the puzzle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final puzzle = PuzzleRegistry.findById(widget.puzzleId);
      if (puzzle != null) {
        ref.read(gameControllerProvider.notifier).loadPuzzle(puzzle);
      } else if (widget.puzzleId.startsWith('daily_')) {
        // Daily puzzle
        final daily = ref.read(dailyProvider);
        ref.read(gameControllerProvider.notifier).loadPuzzle(daily.puzzle);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _starControllers) {
      c.dispose();
    }
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
    return _totalSatisfied(state) / (state.puzzle.gridSize * 2);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Detect zero lives
    ref.listen(gameControllerProvider, (prev, next) {
      if (next.livesRemaining <= 0 && (prev?.livesRemaining ?? 3) > 0) {
        HapticFeedback.heavyImpact();
        _timer?.cancel();
        setState(() => _showZeroLives = true);
      }
    });

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
        // Handle daily puzzle completion
        if (next.puzzle.id.startsWith('daily_')) {
          ref.read(dailyProvider.notifier).completeDaily(_elapsedSeconds);
        }
        // Check achievements
        final progressState = ref.read(progressProvider);
        ref.read(achievementsProvider.notifier).checkAfterPuzzle(progressState, next.mistakes);
        setState(() => _showComplete = true);
        // Staggered star animation
        for (int i = 0; i < 3; i++) {
          Future.delayed(Duration(milliseconds: 200 + i * 200), () {
            if (mounted) _starControllers[i].forward(from: 0);
          });
        }
        // Show achievement popup after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          final unlocked = ref.read(achievementsProvider.notifier).consumeLastUnlocked();
          if (unlocked != null) {
            final achievement = AchievementsController.achievements.firstWhere((a) => a.id == unlocked);
            _showAchievementPopup(achievement);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress bar
                _buildProgressBar(state),
                // Top bar
                _buildTopBar(state),
                // HUD
                _buildHUD(state, controller),
                const SizedBox(height: 8),
                // Grid
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: NonogramGridWidget(
                        state: state,
                        onCellTap: (row, col) {
                          controller.tapCell(row, col);
                          // Auto-clear error cells after delay
                          if (state.errorCells.isEmpty) {
                            Future.delayed(const Duration(milliseconds: 600), () {
                              if (mounted) controller.clearErrors();
                            });
                          }
                        },
                        onHintTap: (row, col) {
                          final used = controller.useHintOnCell(row, col);
                          if (used) {
                            HapticFeedback.mediumImpact();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                // Mode toggle
                _buildModeToggle(state, controller),
                const SizedBox(height: 16),
              ],
            ),
            // Zero lives overlay
            if (_showZeroLives) _buildZeroLivesOverlay(controller),
            // Completion overlay
            if (_showComplete) _buildCompletionOverlay(state, controller),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProgressBar(NonogramState state) {
    final progress = _completionProgress(state);
    return Container(
      height: 6,
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
            '${PuzzleRegistry.findPackById(state.puzzle.packId)?.name ?? state.puzzle.packId} / ${state.puzzle.title}',
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

  Widget _buildHUD(NonogramState state, GameController controller) {
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
          // Satisfied constraints
          Text(
            '${_totalSatisfied(state)}/${state.puzzle.gridSize * 2}',
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          // Hint button
          GestureDetector(
            onTap: () {
              if (state.isHintMode) {
                controller.exitHintMode();
              } else {
                controller.enterHintMode();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isHintMode
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.isHintMode
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                state.isHintMode ? 'TAP CELL' : '\u{1F4A1} HINT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: state.isHintMode ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _totalSatisfied(NonogramState state) {
    int count = 0;
    for (int r = 0; r < state.puzzle.gridSize; r++) {
      if (state.isRowSatisfied(r)) count++;
    }
    for (int c = 0; c < state.puzzle.gridSize; c++) {
      if (state.isColSatisfied(c)) count++;
    }
    return count;
  }

  Widget _buildModeToggle(NonogramState state, GameController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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

  Widget _buildZeroLivesOverlay(GameController controller) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
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
                color: AppColors.hearts.withValues(alpha: 0.1),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.primaryGradient,
                ).createShader(bounds),
                child: const Text(
                  'Need More Lives?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Depleted hearts
              const Text(
                '\u2661 \u2661 \u2661',
                style: TextStyle(fontSize: 24, color: Color(0xFF661111)),
              ),
              const SizedBox(height: 16),
              // Watch ad button (placeholder)
              GestureDetector(
                onTap: () {
                  // Restore lives (simulate ad watched)
                  controller.restoreLives();
                  _startTimer();
                  setState(() => _showZeroLives = false);
                },
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'RESTORE 3 \u2764',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1a0a00),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quit button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save & Exit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your progress is safe',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay(NonogramState state, GameController controller) {
    final score = _calculateScore(state);
    final stars = _calculateStars(state);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
      color: AppColors.background.withValues(alpha: 0.85),
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
                style: AppFonts.pixel(
                  fontSize: 12,
                  color: const Color(0xFF00E676),
                  letterSpacing: 1,
                ).copyWith(
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
              const SizedBox(height: 12),
              // Pixel art reveal
              PixelArtReveal(puzzle: state.puzzle),
              const SizedBox(height: 12),
              // Stars (staggered animation)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final filled = i < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ScaleTransition(
                      scale: filled ? _starAnimations[i] : const AlwaysStoppedAnimation(1.0),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NEXT PUZZLE',
                        style: AppFonts.pixel(
                          fontSize: 9,
                          color: const Color(0xFF1a0a00),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Color(0xFF1a0a00)),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  void _showAchievementPopup(Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primaryDark.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(achievement.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
