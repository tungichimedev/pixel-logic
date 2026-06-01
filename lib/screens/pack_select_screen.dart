import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/progress_controller.dart';
import '../utils/app_theme.dart';
import '../utils/puzzle_registry.dart';

class PackSelectScreen extends ConsumerWidget {
  final String packId;

  const PackSelectScreen({super.key, required this.packId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = PuzzleRegistry.findPackById(packId);
    if (pack == null) {
      return const Scaffold(body: Center(child: Text('Pack not found')));
    }

    final progress = ref.watch(progressProvider);
    final completed = progress.results.keys
        .where((id) => pack.puzzles.any((p) => p.id == id))
        .length;
    final totalStars = progress.starsInPack(
      pack.id,
      pack.puzzles.map((p) => p.id).toList(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    '${pack.emoji} ${pack.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completed/${pack.puzzles.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pack.puzzles.isNotEmpty
                          ? completed / pack.puzzles.length
                          : 0,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$completed/${pack.puzzles.length} Puzzles',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\u2605 $totalStars/${pack.puzzles.length * 3}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Puzzle grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: pack.puzzles.length,
                itemBuilder: (context, index) {
                  final puzzle = pack.puzzles[index];
                  final result = progress.results[puzzle.id];
                  final isCompleted = result != null;
                  final isNext = !isCompleted &&
                      (index == 0 ||
                          progress.results.containsKey(
                              pack.puzzles[index - 1].id));

                  return _buildPuzzleTile(
                    context, puzzle.title, puzzle.gridSize,
                    index + 1, isCompleted, isNext,
                    result?.starsEarned ?? 0,
                    () => context.push('/play/${puzzle.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleTile(
    BuildContext context,
    String title, int gridSize,
    int number, bool completed, bool isNext, int stars,
    VoidCallback onTap,
  ) {
    final locked = !completed && !isNext;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: completed
              ? AppColors.surface
              : isNext
                  ? AppColors.surface
                  : AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNext
                ? AppColors.primary.withValues(alpha: 0.5)
                : completed
                    ? AppColors.satisfied.withValues(alpha: 0.3)
                    : AppColors.borderSubtle,
            width: isNext ? 2 : 1,
          ),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (completed)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.satisfied, size: 24),
            if (locked)
              Icon(Icons.lock_rounded,
                  color: AppColors.textMuted, size: 24),
            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    color: Color(0xFF1a0a00),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '#$number',
              style: TextStyle(
                color: locked ? AppColors.textMuted : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: locked ? AppColors.textMuted : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${gridSize}x$gridSize',
              style: TextStyle(
                color: locked ? AppColors.textMuted : AppColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (completed) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < stars
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.3),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
