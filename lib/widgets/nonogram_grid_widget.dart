import 'package:flutter/material.dart';
import '../models/nonogram_state.dart';

class NonogramGridWidget extends StatelessWidget {
  final NonogramState state;
  final void Function(int row, int col) onCellTap;

  const NonogramGridWidget({
    super.key,
    required this.state,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = state.puzzle.gridSize;
    final maxClueWidth = _maxRowClueWidth(context);
    final maxClueHeight = _maxColClueHeight(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - maxClueWidth - 8;
        final cellSize = (availableWidth / gridSize).clamp(28.0, 48.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Column clues row
            Padding(
              padding: EdgeInsets.only(left: maxClueWidth + 4),
              child: SizedBox(
                height: maxClueHeight,
                child: Row(
                  children: List.generate(gridSize, (col) {
                    final satisfied = state.isColSatisfied(col);
                    return SizedBox(
                      width: cellSize,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: state.puzzle.colClues[col].runs.map((r) {
                          return Text(
                            '$r',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: satisfied
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF9999CC),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Grid rows with row clues
            ...List.generate(gridSize, (row) {
              final satisfied = state.isRowSatisfied(row);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row clue
                  SizedBox(
                    width: maxClueWidth,
                    child: Container(
                      decoration: satisfied
                          ? BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        state.puzzle.rowClues[row].runs.join(' '),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: satisfied
                              ? const Color(0xFF00E676)
                              : const Color(0xFF9999CC),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Grid cells
                  ...List.generate(gridSize, (col) {
                    return GestureDetector(
                      onTap: () => onCellTap(row, col),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(0.5),
                        decoration: _cellDecoration(state.cells[row][col]),
                        child: _cellChild(state.cells[row][col], cellSize),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  BoxDecoration _cellDecoration(CellState cell) {
    switch (cell) {
      case CellState.empty:
        return BoxDecoration(
          color: const Color(0xFF1a1850),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        );
      case CellState.filled:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5599FF), Color(0xFF4488FF), Color(0xFF3377EE)],
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4488FF).withValues(alpha: 0.4),
              blurRadius: 3,
            ),
          ],
        );
      case CellState.marked:
        return BoxDecoration(
          color: const Color(0xFF1a1850),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        );
      case CellState.revealed:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5599FF), Color(0xFF4488FF)],
          ),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
        );
    }
  }

  Widget? _cellChild(CellState cell, double size) {
    if (cell == CellState.marked) {
      return Center(
        child: Text(
          'X',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      );
    }
    return null;
  }

  double _maxRowClueWidth(BuildContext context) {
    int maxNums = 1;
    for (final clue in state.puzzle.rowClues) {
      if (clue.runs.length > maxNums) maxNums = clue.runs.length;
    }
    return (maxNums * 14.0 + 8).clamp(32.0, 80.0);
  }

  double _maxColClueHeight(BuildContext context) {
    int maxNums = 1;
    for (final clue in state.puzzle.colClues) {
      if (clue.runs.length > maxNums) maxNums = clue.runs.length;
    }
    return (maxNums * 16.0 + 4).clamp(24.0, 80.0);
  }
}
