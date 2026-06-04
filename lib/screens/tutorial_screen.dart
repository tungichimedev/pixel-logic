import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class TutorialScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialScreen({super.key, required this.onComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  // Tutorial 3x3 grid state
  final _cells = List.generate(3, (_) => List.filled(3, false));

  // Target pattern (L shape)
  final _solution = [
    [true, false, false],
    [true, false, false],
    [true, true, true],
  ];

  final _steps = [
    (
      title: 'Read the Clues',
      desc: 'Numbers on the left and top tell you how many cells to fill in each row and column.',
    ),
    (
      title: 'Fill Cells',
      desc: 'Tap a cell to fill it. The clue "3" means fill 3 cells in a row.',
    ),
    (
      title: 'Check Satisfaction',
      desc: 'When a row or column is correctly filled, the clue turns green!',
    ),
    (
      title: 'Solve the Puzzle!',
      desc: 'Fill all the correct cells to reveal the hidden picture. Try completing this one!',
    ),
  ];

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isSolved {
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (_cells[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
  }

  bool _showComplete = false;

  bool _advancing = false;

  void _tapCell(int row, int col) {
    // Step 1 (fill bottom row) — allow tapping row 2 only
    if (_step == 1) {
      if (row != 2 || _cells[row][col] || _advancing) return;
      HapticFeedback.lightImpact();
      setState(() {
        _cells[row][col] = true;
        if (_cells[2][0] && _cells[2][1] && _cells[2][2]) {
          _advancing = true;
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              setState(() {
                _step = 2;
                _advancing = false;
              });
            }
          });
        }
      });
      return;
    }
    // Step 3 (solve) — fill to complete L shape
    if (_step == 3) {
      HapticFeedback.lightImpact();
      setState(() {
        _cells[row][col] = !_cells[row][col];
        if (_cells[row][col] && !_solution[row][col]) {
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _cells[row][col] = false);
          });
          return;
        }
        if (_isSolved) {
          HapticFeedback.heavyImpact();
          setState(() => _showComplete = true);
          Future.delayed(const Duration(milliseconds: 1200), () {
            _completeTutorial();
          });
        }
      });
      return;
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_complete', true);
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_step];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Title
                Text(
                  'HOW TO PLAY',
                  style: AppFonts.pixel(
                      fontSize: 11, color: Colors.white, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                // Step title
                Text(
                  currentStep.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentStep.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Tutorial grid with tooltip
                _buildGridWithTooltip(),
                const SizedBox(height: 20),
                // Step-specific visual hint
                _buildStepVisual(),
                // Puzzle complete card (step 4)
                if (_showComplete) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.satisfied.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.satisfied.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'PUZZLE COMPLETE!',
                          style: AppFonts.pixel(
                              fontSize: 11, color: AppColors.satisfied),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Auto-advances to Home',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Step 4 preview (faded, before completion)
                if (_step == 3 && !_showComplete) ...[
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.satisfied.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.satisfied.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'PUZZLE COMPLETE!',
                            style: AppFonts.pixel(
                                fontSize: 11, color: AppColors.satisfied),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Auto-advances to Home',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Step counter
                Text(
                  'Step ${_step + 1} of 4',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Buttons
                if (!_showComplete) _buildButtons(),
                // Step 1 gated message
                if (_step == 1 &&
                    !_cells[2][0] &&
                    !_cells[2][1] &&
                    !_cells[2][2])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Fill the cells above to continue',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridWithTooltip() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(child: _buildTutorialGrid()),
        // Tooltip on step 0 pointing at clues
        if (_step == 0)
          Positioned(
            top: -50,
            left: MediaQuery.of(context).size.width * 0.25,
            child: _buildTooltip('These numbers\nare your clues!'),
          ),
      ],
    );
  }

  Widget _buildTooltip(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF140E37).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepVisual() {
    final visuals = [
      (
        icon: '\u2191',
        text: 'Look at the numbers above and to the left',
        color: AppColors.primary
      ),
      (
        icon: '\u261D',
        text: 'Tap the bottom row to fill all 3 cells',
        color: AppColors.cellFilled
      ),
      (
        icon: '\u2713',
        text: 'See? Both the row AND column clue turned green!',
        color: AppColors.satisfied
      ),
      (
        icon: '\u261D',
        text: 'Fill the left column to complete the puzzle!',
        color: AppColors.primary
      ),
    ];
    final v = visuals[_step];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: v.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(v.icon, style: TextStyle(fontSize: 20, color: v.color)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v.text,
              style: TextStyle(
                color: v.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          // Skip — visible from step 2+
          if (_step >= 2)
            GestureDetector(
              onTap: _completeTutorial,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          // Next button — only on step 0 and 2
          if (_step == 0 || _step == 2)
            GestureDetector(
              onTap: () => setState(() => _step++),
              child: Container(
                width: 180,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'NEXT',
                      style: TextStyle(
                        color: Color(0xFF1a0a00),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF1a0a00)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTutorialGrid() {
    final rowClues = ['1', '1', '3'];
    final colClues = ['3', '1', '1'];
    const cellSize = 28.0;
    const clueWidth = 32.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column clues
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: clueWidth),
            ...List.generate(3, (col) {
              final satisfied = _isColSatisfied(col);
              final highlight = _step == 0; // gold on step 0
              return SizedBox(
                width: cellSize + 2,
                child: Text(
                  colClues[col],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: satisfied
                        ? AppColors.satisfied
                        : highlight
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 2),
        // Rows
        ...List.generate(3, (row) {
          final satisfied = _isRowSatisfied(row);
          final highlight = _step == 0; // gold on step 0
          final isStep1HighlightRow = _step == 1 && row == 2;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row clue
              Container(
                width: clueWidth,
                height: cellSize,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 4),
                decoration: satisfied
                    ? BoxDecoration(
                        color: AppColors.satisfied.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: Text(
                  rowClues[row],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: satisfied
                        ? AppColors.satisfied
                        : isStep1HighlightRow
                            ? AppColors.primary
                            : highlight
                                ? AppColors.primary
                                : AppColors.textSecondary,
                  ),
                ),
              ),
              ...List.generate(3, (col) {
                final filled = _cells[row][col];
                final shouldPulse = (_step == 1 && row == 2 && !filled) ||
                    (_step == 3 &&
                        _solution[row][col] &&
                        !filled);

                return GestureDetector(
                  onTap: () => _tapCell(row, col),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulseOpacity =
                          shouldPulse ? 0.3 + _pulseController.value * 0.7 : 1.0;
                      return Opacity(
                        opacity: shouldPulse ? pulseOpacity : 1.0,
                        child: child,
                      );
                    },
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        gradient: filled
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF5599FF),
                                  Color(0xFF4488FF),
                                  Color(0xFF3377EE),
                                ],
                              )
                            : null,
                        color: filled
                            ? null
                            : shouldPulse
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: shouldPulse
                              ? AppColors.primary
                              : filled
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.12),
                          width: shouldPulse ? 2 : 1,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: AppColors.cellFilled
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  bool _isRowSatisfied(int row) {
    final expected = _solution[row].where((c) => c).length;
    final actual = _cells[row].where((c) => c).length;
    if (actual != expected) return false;
    for (int c = 0; c < 3; c++) {
      if (_cells[row][c] != _solution[row][c]) return false;
    }
    return true;
  }

  bool _isColSatisfied(int col) {
    final expected =
        List.generate(3, (r) => _solution[r][col]).where((c) => c).length;
    final actual =
        List.generate(3, (r) => _cells[r][col]).where((c) => c).length;
    if (actual != expected) return false;
    for (int r = 0; r < 3; r++) {
      if (_cells[r][col] != _solution[r][col]) return false;
    }
    return true;
  }
}
