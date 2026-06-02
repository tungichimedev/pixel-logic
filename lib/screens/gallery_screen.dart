import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/progress_controller.dart';
import '../utils/app_theme.dart';
import '../utils/puzzle_registry.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final completedPuzzles = <({String title, String packName, int stars, int gridSize})>[];

    for (final pack in PuzzleRegistry.packs) {
      for (final puzzle in pack.puzzles) {
        final result = progress.results[puzzle.id];
        if (result != null) {
          completedPuzzles.add((
            title: puzzle.title,
            packName: pack.name,
            stars: result.starsEarned,
            gridSize: puzzle.gridSize,
          ));
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'GALLERY',
                style: AppFonts.pixel(fontSize: 12, color: AppColors.primary, letterSpacing: 2),
              ),
            ),
            // Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('${completedPuzzles.length}', 'SOLVED'),
                    _statCol(
                      '${completedPuzzles.fold<int>(0, (s, p) => s + p.stars)}',
                      'STARS',
                    ),
                    _statCol('${progress.level}', 'LEVEL'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gallery grid
            Expanded(
              child: completedPuzzles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.collections_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          const Text(
                            'No puzzles completed yet',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Solve puzzles to build your collection!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'START YOUR FIRST PUZZLE \u2192',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: completedPuzzles.length,
                      itemBuilder: (context, index) {
                        final p = completedPuzzles[index];
                        return _galleryTile(p.title, p.packName, p.stars, p.gridSize);
                      },
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _statCol(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ],
    );
  }

  Widget _galleryTile(String title, String packName, int stars, int gridSize) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.satisfied.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.satisfied, size: 28),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          Text('$packName \u2022 ${gridSize}x$gridSize',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Icon(
                Icons.star_rounded,
                size: 14,
                color: i < stars ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3),
              );
            }),
          ),
        ],
      ),
    );
  }
}
