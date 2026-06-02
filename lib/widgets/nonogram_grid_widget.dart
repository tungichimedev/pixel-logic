import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/nonogram_state.dart';

class NonogramGridWidget extends StatefulWidget {
  final NonogramState state;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col)? onHintTap;

  const NonogramGridWidget({
    super.key,
    required this.state,
    required this.onCellTap,
    this.onHintTap,
  });

  @override
  State<NonogramGridWidget> createState() => _NonogramGridWidgetState();
}

class _NonogramGridWidgetState extends State<NonogramGridWidget> {
  // Drag state
  int? _dragAxis; // 0 = horizontal, 1 = vertical, null = undecided
  int? _dragStartRow;
  int? _dragStartCol;
  final Set<String> _draggedCells = {};
  double _cellSize = 32;
  double _clueWidth = 40;
  double _clueHeight = 40;

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.state.puzzle.gridSize;
    _clueWidth = _maxRowClueWidth();
    _clueHeight = _maxColClueHeight();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - _clueWidth - 8;
        _cellSize = (availableWidth / gridSize).clamp(32.0, 52.0);
        final gridPixelSize = _cellSize * gridSize + gridSize; // +gaps

        return GestureDetector(
          onPanStart: (d) => _onDragStart(d.localPosition),
          onPanUpdate: (d) => _onDragUpdate(d.localPosition),
          onPanEnd: (_) => _onDragEnd(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column clues
              Padding(
                padding: EdgeInsets.only(left: _clueWidth + 4),
                child: SizedBox(
                  width: gridPixelSize,
                  height: _clueHeight,
                  child: Row(
                    children: List.generate(gridSize, (col) {
                      final satisfied = widget.state.isColSatisfied(col);
                      return SizedBox(
                        width: _cellSize,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: widget.state.puzzle.colClues[col].runs
                              .map((r) => Text(
                                    '$r',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: satisfied
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFF9999CC),
                                    ),
                                  ))
                              .toList(),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Grid rows
              ...List.generate(gridSize, (row) {
                final satisfied = widget.state.isRowSatisfied(row);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row clue
                    SizedBox(
                      width: _clueWidth,
                      child: Container(
                        decoration: satisfied
                            ? BoxDecoration(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text(
                          widget.state.puzzle.rowClues[row].runs.join(' '),
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
                    // Cells
                    ...List.generate(gridSize, (col) {
                      final isError = widget.state.errorCells.contains((row, col));
                      final isHintTarget = widget.state.isHintMode &&
                          widget.state.cells[row][col] != CellState.filled &&
                          widget.state.cells[row][col] != CellState.revealed;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (widget.state.isHintMode && widget.onHintTap != null) {
                            widget.onHintTap!(row, col);
                          } else {
                            widget.onCellTap(row, col);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _cellSize,
                          height: _cellSize,
                          margin: const EdgeInsets.all(0.5),
                          decoration: isError
                              ? _errorDecoration()
                              : _cellDecoration(widget.state.cells[row][col], isHintTarget: isHintTarget),
                          child: isError
                              ? _errorChild(_cellSize)
                              : _cellChild(widget.state.cells[row][col], _cellSize),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- Drag-fill logic ---

  (int, int)? _hitTest(Offset pos) {
    final gridSize = widget.state.puzzle.gridSize;
    final gridStartX = _clueWidth + 4;
    final gridStartY = _clueHeight + 2;

    final x = pos.dx - gridStartX;
    final y = pos.dy - gridStartY;

    if (x < 0 || y < 0) return null;

    final col = (x / (_cellSize + 1)).floor();
    final row = (y / (_cellSize + 1)).floor();

    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return null;
    return (row, col);
  }

  void _onDragStart(Offset pos) {
    final hit = _hitTest(pos);
    if (hit == null) return;
    _dragStartRow = hit.$1;
    _dragStartCol = hit.$2;
    _dragAxis = null;
    _draggedCells.clear();

    final key = '${hit.$1},${hit.$2}';
    _draggedCells.add(key);
    HapticFeedback.lightImpact();
    widget.onCellTap(hit.$1, hit.$2);
  }

  void _onDragUpdate(Offset pos) {
    if (_dragStartRow == null) return;
    final hit = _hitTest(pos);
    if (hit == null) return;

    final row = hit.$1;
    final col = hit.$2;

    // Determine axis on first move away from start
    if (_dragAxis == null && (row != _dragStartRow || col != _dragStartCol)) {
      if ((row - _dragStartRow!).abs() >= (col - _dragStartCol!).abs()) {
        _dragAxis = 1; // vertical
      } else {
        _dragAxis = 0; // horizontal
      }
    }

    // Lock to axis
    int targetRow = row;
    int targetCol = col;
    if (_dragAxis == 0) {
      targetRow = _dragStartRow!; // lock row
    } else if (_dragAxis == 1) {
      targetCol = _dragStartCol!; // lock col
    }

    final key = '$targetRow,$targetCol';
    if (!_draggedCells.contains(key)) {
      _draggedCells.add(key);
      HapticFeedback.selectionClick();
      widget.onCellTap(targetRow, targetCol);
    }
  }

  void _onDragEnd() {
    _dragStartRow = null;
    _dragStartCol = null;
    _dragAxis = null;
    _draggedCells.clear();
  }

  // --- Cell visuals ---

  BoxDecoration _cellDecoration(CellState cell, {bool isHintTarget = false}) {
    if (isHintTarget) {
      return BoxDecoration(
        color: const Color(0xFF1a1850),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color(0xFFFFD84B).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD84B).withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      );
    }
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
          border:
              Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
        );
    }
  }

  BoxDecoration _errorDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF4444), Color(0xFFFF3B30)],
      ),
      borderRadius: BorderRadius.circular(2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
          blurRadius: 6,
        ),
      ],
    );
  }

  Widget? _errorChild(double size) {
    return Center(
      child: Text(
        '\u2715',
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget? _cellChild(CellState cell, double size) {
    if (cell == CellState.marked) {
      return Center(
        child: Text(
          'X',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      );
    }
    return null;
  }

  double _maxRowClueWidth() {
    int maxNums = 1;
    for (final clue in widget.state.puzzle.rowClues) {
      if (clue.runs.length > maxNums) maxNums = clue.runs.length;
    }
    return (maxNums * 14.0 + 8).clamp(32.0, 80.0);
  }

  double _maxColClueHeight() {
    int maxNums = 1;
    for (final clue in widget.state.puzzle.colClues) {
      if (clue.runs.length > maxNums) maxNums = clue.runs.length;
    }
    return (maxNums * 16.0 + 4).clamp(24.0, 80.0);
  }
}
