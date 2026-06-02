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

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;

  // Tutorial 3x3 grid state
  final _cells = List.generate(3, (_) => List.filled(3, false));

  // Target pattern (simple L shape)
  final _solution = [
    [true, false, false],
    [true, false, false],
    [true, true, true],
  ];

  final _steps = [
    (
      title: 'Read the Clues',
      desc: 'Numbers on the left and top tell you how many cells to fill in each row and column.',
      highlight: 'clues',
    ),
    (
      title: 'Fill Cells',
      desc: 'Tap a cell to fill it. The clue "3" means fill 3 cells in a row.',
      highlight: 'row3',
    ),
    (
      title: 'Check Satisfaction',
      desc: 'See? Both the row AND column clue turned green!',
      highlight: 'satisfied',
    ),
    (
      title: 'Solve the Puzzle!',
      desc: 'Fill all the correct cells to reveal the hidden picture. Try completing this one!',
      highlight: 'solve',
    ),
  ];

  bool get _isSolved {
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (_cells[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
  }

  bool _showComplete = false;

  void _tapCell(int row, int col) {
    // Step 1 (fill bottom row) — allow tapping row 2 only
    if (_step == 1) {
      if (row != 2) return;
      HapticFeedback.lightImpact();
      setState(() {
        _cells[row][col] = true;
        // Auto-advance when bottom row complete
        if (_cells[2][0] && _cells[2][1] && _cells[2][2]) {
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _step = 2);
          });
        }
      });
      return;
    }
    // Step 3 (solve) — fill left column to complete L shape
    if (_step == 3) {
      HapticFeedback.lightImpact();
      setState(() {
        _cells[row][col] = !_cells[row][col];
        // Wrong cell — flash and reset
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
    // Steps 0 and 2 — no tapping allowed (read-only)
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
                style: AppFonts.pixel(fontSize: 14, color: AppColors.primary, letterSpacing: 2),
              ),
              const SizedBox(height: 32),
              // Step title
              Text(
                currentStep.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentStep.desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Tutorial grid
              _buildTutorialGrid(),
              const SizedBox(height: 24),
              // Step-specific visual hint
              _buildStepVisual(),
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
              const SizedBox(height: 16),
              // Completion flash
              if (_showComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.satisfied.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.satisfied.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'PUZZLE COMPLETE!',
                    style: AppFonts.pixel(fontSize: 10, color: AppColors.satisfied),
                  ),
                ),
              if (!_showComplete) ...[
              // Buttons
              Row(
                children: [
                  // Skip — only visible from step 2+
                  if (_step >= 2)
                    TextButton(
                      onPressed: _completeTutorial,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  // Next — hidden on step 1 (gated) and step 3 (user completes)
                  if (_step == 0 || _step == 2)
                    GestureDetector(
                      onTap: () => setState(() => _step++),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NEXT',
                              style: TextStyle(
                                color: Color(0xFF1a0a00),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF1a0a00)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              ],
              // Step 1 gated message
              if (_step == 1 && !_cells[2][0] && !_cells[2][1] && !_cells[2][2])
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Fill the cells above to continue',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStepVisual() {
    final visuals = [
      // Step 0: Read clues
      (icon: Icons.arrow_upward_rounded, text: 'Look at the numbers above and to the left', color: AppColors.primary),
      // Step 1: Fill cells
      (icon: Icons.touch_app_rounded, text: 'Tap the bottom row to fill all 3 cells', color: AppColors.cellFilled),
      // Step 2: Check satisfaction
      (icon: Icons.check_circle_outline_rounded, text: 'Green clues mean that row or column is correct', color: AppColors.satisfied),
      // Step 3: Solve
      (icon: Icons.touch_app_rounded, text: 'Fill the left column to complete the puzzle!', color: AppColors.primary),
    ];
    final v = visuals[_step];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: v.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(v.icon, color: v.color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v.text,
              style: TextStyle(
                color: v.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialGrid() {
    // Row clues for L-shape: [1], [1], [3]
    // Col clues: [3], [1], [1]
    final rowClues = ['1', '1', '3'];
    final colClues = ['3', '1', '1'];
    const cellSize = 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column clues
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 40),
            ...List.generate(3, (col) {
              final satisfied = _isColSatisfied(col);
              return SizedBox(
                width: cellSize + 2,
                child: Text(
                  colClues[col],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: satisfied ? AppColors.satisfied : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        // Rows
        ...List.generate(3, (row) {
          final satisfied = _isRowSatisfied(row);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  rowClues[row],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: satisfied ? AppColors.satisfied : AppColors.textSecondary,
                  ),
                ),
              ),
              ...List.generate(3, (col) {
                final filled = _cells[row][col];
                final shouldPulse = _step == 1 && row == 2 && !_cells[row][col];
                return GestureDetector(
                  onTap: () => _tapCell(row, col),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      gradient: filled
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF5599FF), Color(0xFF4488FF)],
                            )
                          : null,
                      color: filled ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: shouldPulse
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : filled
                                ? Colors.transparent
                                : AppColors.borderMedium,
                        width: shouldPulse ? 2 : 1,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: AppColors.cellFilled.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
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
    // Check pattern matches
    if (actual != expected) return false;
    for (int c = 0; c < 3; c++) {
      if (_cells[row][c] != _solution[row][c]) return false;
    }
    return true;
  }

  bool _isColSatisfied(int col) {
    final expected = List.generate(3, (r) => _solution[r][col]).where((c) => c).length;
    final actual = List.generate(3, (r) => _cells[r][col]).where((c) => c).length;
    if (actual != expected) return false;
    for (int r = 0; r < 3; r++) {
      if (_cells[r][col] != _solution[r][col]) return false;
    }
    return true;
  }
}
