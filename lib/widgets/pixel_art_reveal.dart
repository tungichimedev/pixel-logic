import 'package:flutter/material.dart';
import '../models/nonogram_puzzle.dart';

class PixelArtReveal extends StatefulWidget {
  final NonogramPuzzle puzzle;

  const PixelArtReveal({super.key, required this.puzzle});

  @override
  State<PixelArtReveal> createState() => _PixelArtRevealState();
}

class _PixelArtRevealState extends State<PixelArtReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.puzzle.gridSize;
    final totalCells = size * size;
    final palette = widget.puzzle.colorPalette;
    final defaultColor = palette.isNotEmpty ? Color(palette[0]) : const Color(0xFF4488FF);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final revealedCount = (_controller.value * totalCells).floor();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.15 + _controller.value * 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: size * 20.0,
              height: size * 20.0,
              child: Column(
                children: List.generate(size, (row) {
                  return Row(
                    children: List.generate(size, (col) {
                      final cellIndex = row * size + col;
                      final isRevealed = cellIndex < revealedCount;
                      final isFilled = widget.puzzle.solution[row][col] > 0;
                      final colorIndex = widget.puzzle.solution[row][col];

                      Color cellColor;
                      if (!isRevealed) {
                        cellColor = const Color(0xFF1a1850);
                      } else if (isFilled) {
                        cellColor = colorIndex > 0 && colorIndex <= palette.length
                            ? Color(palette[colorIndex - 1])
                            : defaultColor;
                      } else {
                        cellColor = const Color(0xFF0d0b22);
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 20,
                        height: 20,
                        color: cellColor,
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
