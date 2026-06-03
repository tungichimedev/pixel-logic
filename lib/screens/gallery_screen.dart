import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/progress_controller.dart';
import '../models/nonogram_puzzle.dart';
import '../utils/app_theme.dart';
import '../utils/puzzle_registry.dart';
import '../widgets/banner_ad_widget.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _filterPack = 'all'; // 'all', pack id

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final completedPuzzles = <({String title, String packName, String packId, int stars, int gridSize, NonogramPuzzle puzzle})>[];

    for (final pack in PuzzleRegistry.packs) {
      for (final puzzle in pack.puzzles) {
        final result = progress.results[puzzle.id];
        if (result != null) {
          completedPuzzles.add((
            title: puzzle.title,
            packName: pack.name,
            packId: pack.id,
            stars: result.starsEarned,
            gridSize: puzzle.gridSize,
            puzzle: puzzle,
          ));
        }
      }
    }

    final filtered = _filterPack == 'all'
        ? completedPuzzles
        : completedPuzzles.where((p) => p.packId == _filterPack).toList();

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
            const SizedBox(height: 12),
            // Pack filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChip('all', 'ALL'),
                  const SizedBox(width: 6),
                  ...PuzzleRegistry.packs.map((pack) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _filterChip(pack.id, pack.name),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Banner ad
            const BannerAdWidget(),
            // Gallery grid
            Expanded(
              child: filtered.isEmpty
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
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return _galleryTile(p.title, p.packName, p.stars, p.gridSize, p.puzzle);
                      },
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final active = _filterPack == id;
    return GestureDetector(
      onTap: () => setState(() => _filterPack = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
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

  Widget _galleryTile(String title, String packName, int stars, int gridSize, NonogramPuzzle puzzle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.satisfied.withValues(alpha: 0.08),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.satisfied.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini pixel art thumbnail
          _buildMiniPixelArt(puzzle),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
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

  Widget _buildMiniPixelArt(NonogramPuzzle puzzle) {
    final size = puzzle.gridSize;
    final cellPx = size <= 5 ? 8.0 : 4.0;
    return SizedBox(
      width: cellPx * size + size - 1,
      height: cellPx * size + size - 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(size, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(size, (c) {
              final isFilled = puzzle.solution[r][c] > 0;
              return Container(
                width: cellPx,
                height: cellPx,
                margin: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: isFilled
                      ? AppColors.cellFilled
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
