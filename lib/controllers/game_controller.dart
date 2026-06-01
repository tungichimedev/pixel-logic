import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nonogram_puzzle.dart';
import '../models/nonogram_state.dart';

class GameController extends Notifier<NonogramState> {
  @override
  NonogramState build() {
    return NonogramState.initial(_samplePuzzle());
  }

  void loadPuzzle(NonogramPuzzle puzzle) {
    state = NonogramState.initial(puzzle);
  }

  void tapCell(int row, int col) {
    if (state.isComplete) return;
    if (row < 0 || row >= state.puzzle.gridSize) return;
    if (col < 0 || col >= state.puzzle.gridSize) return;

    final currentCell = state.cells[row][col];
    if (currentCell == CellState.revealed) return;

    final newCells = state.cells.map((r) => List<CellState>.from(r)).toList();

    if (state.inputMode == InputMode.fill) {
      if (currentCell == CellState.filled) {
        newCells[row][col] = CellState.empty;
      } else {
        // Check if correct (error checking)
        if (!state.puristMode && !state.isCellCorrect(row, col)) {
          // Wrong cell — lose a life
          state = state.copyWith(
            livesRemaining: state.livesRemaining - 1,
            mistakes: state.mistakes + 1,
          );
          return;
        }
        newCells[row][col] = CellState.filled;
      }
    } else {
      // Mark mode
      if (currentCell == CellState.marked) {
        newCells[row][col] = CellState.empty;
      } else if (currentCell == CellState.empty) {
        newCells[row][col] = CellState.marked;
      }
    }

    final newState = state.copyWith(cells: newCells);
    if (newState.checkComplete) {
      state = newState.copyWith(isComplete: true);
    } else {
      state = newState;
    }
  }

  void toggleMode() {
    state = state.copyWith(
      inputMode: state.inputMode == InputMode.fill
          ? InputMode.mark
          : InputMode.fill,
    );
  }

  void resetPuzzle() {
    state = NonogramState.initial(state.puzzle);
  }

  static NonogramPuzzle _samplePuzzle() {
    // 5x5 Heart
    return NonogramPuzzle.fromPixelGrid(
      id: 'sample_heart',
      title: 'Heart',
      packId: 'animals',
      grid: [
        [0, 1, 0, 1, 0],
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
        [0, 0, 1, 0, 0],
      ],
      parTimeSeconds: 60,
      difficulty: 1,
    );
  }
}

final gameControllerProvider =
    NotifierProvider<GameController, NonogramState>(GameController.new);
