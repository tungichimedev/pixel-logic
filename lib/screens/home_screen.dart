import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/daily_controller.dart';
import '../controllers/progress_controller.dart';
import '../utils/app_theme.dart';
import '../utils/puzzle_registry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFE88A), Color(0xFFFFD84B), Color(0xFFFF9500)],
              ).createShader(bounds),
              child: const Text(
                'PIXEL LOGIC',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
            const Text(
              'NONOGRAM PUZZLES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            // Mini heart decoration
            _buildMiniHeart(),
            const SizedBox(height: 12),
            // Daily puzzle banner
            _buildDailyBanner(context, ref),
            const SizedBox(height: 12),
            // Player stats
            _buildPlayerStats(progress),
            const SizedBox(height: 12),
            // Pack list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: PuzzleRegistry.packs.length,
                itemBuilder: (context, index) {
                  final pack = PuzzleRegistry.packs[index];
                  final completed = progress.results.keys
                      .where((id) => pack.puzzles.any((p) => p.id == id))
                      .length;
                  final totalStars = progress.starsInPack(
                    pack.id,
                    pack.puzzles.map((p) => p.id).toList(),
                  );
                  final isLocked = index > 0 &&
                      _completedInPreviousPack(progress, index) < pack.unlockRequirement;

                  return _buildPackCard(
                    context, pack.name, pack.emoji,
                    completed, pack.puzzles.length,
                    totalStars, pack.puzzles.length * 3,
                    isLocked, pack.unlockRequirement,
                    () => context.push('/pack/${pack.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBanner(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyProvider);
    return GestureDetector(
      onTap: daily.completed
          ? null
          : () => context.push('/play/${daily.puzzle.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primaryDark.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: daily.completed
                    ? const LinearGradient(colors: [AppColors.satisfied, Color(0xFF00C853)])
                    : const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                daily.completed ? Icons.check_rounded : Icons.bolt_rounded,
                color: daily.completed ? Colors.white : const Color(0xFF1a0a00),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY CHALLENGE',
                    style: TextStyle(
                      color: daily.completed ? AppColors.satisfied : AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    daily.completed
                        ? 'Completed! Best: ${_formatTime(daily.bestTimeSeconds ?? 0)}'
                        : '${daily.puzzle.gridSize}x${daily.puzzle.gridSize} \u2022 +100 XP \u2022 +1 Hint',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (!daily.completed)
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _completedInPreviousPack(ProgressState progress, int packIndex) {
    if (packIndex == 0) return 999;
    final prevPack = PuzzleRegistry.packs[packIndex - 1];
    return progress.results.keys
        .where((id) => prevPack.puzzles.any((p) => p.id == id))
        .length;
  }

  Widget _buildMiniHeart() {
    const filled = Color(0xFFFF4F7B);
    const empty = Color(0x15FFFFFF);
    // 5x5 heart pattern
    final pattern = [
      [false, true, false, true, false],
      [true, true, true, true, true],
      [true, true, true, true, true],
      [false, true, true, true, false],
      [false, false, true, false, false],
    ];

    return SizedBox(
      width: 54,
      height: 54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pattern.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((isFilled) {
              return Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: isFilled ? filled : empty,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: isFilled
                      ? [BoxShadow(color: filled.withValues(alpha: 0.4), blurRadius: 3)]
                      : null,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerStats(ProgressState progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lv.${progress.level}',
              style: const TextStyle(
                color: Color(0xFF1a0a00),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // XP bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progress.totalXP % 200) / 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${progress.totalXP % 200} / 200 XP',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Total puzzles
          Text(
            '${progress.results.length} solved',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(
    BuildContext context,
    String name, String emoji,
    int completed, int total,
    int stars, int maxStars,
    bool locked, int unlockReq,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: locked
              ? AppColors.surface.withValues(alpha: 0.3)
              : AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? AppColors.borderSubtle : AppColors.borderMedium,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Text(emoji, style: TextStyle(fontSize: 32, color: locked ? Colors.grey : null)),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: locked ? AppColors.textMuted : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: total > 0 ? completed / total : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.satisfied, Color(0xFF00C853)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locked
                        ? 'Complete $unlockReq puzzles to unlock'
                        : '$completed/$total puzzles  \u2605 $stars/$maxStars',
                    style: TextStyle(
                      color: locked ? AppColors.textMuted : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow or lock
            Icon(
              locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
              color: locked ? AppColors.textMuted : AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
