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
    if (state.isComplete || state.livesRemaining <= 0) return;
    if (row < 0 || row >= state.puzzle.gridSize) return;
    if (col < 0 || col >= state.puzzle.gridSize) return;
    if (state.isHintMode) return; // Don't allow normal taps in hint mode

    final currentCell = state.cells[row][col];
    if (currentCell == CellState.revealed) return;

    final newCells = _copyCells();

    if (state.inputMode == InputMode.fill) {
      if (currentCell == CellState.filled) {
        newCells[row][col] = CellState.empty;
      } else if (currentCell == CellState.marked) {
        // Can't fill a marked cell — unfill the mark first
        return;
      } else {
        if (!state.puristMode && !state.isCellCorrect(row, col)) {
          // Wrong cell — add to error set, lose a life
          final newErrors = Set<(int, int)>.from(state.errorCells)..add((row, col));
          state = state.copyWith(
            livesRemaining: state.livesRemaining - 1,
            mistakes: state.mistakes + 1,
            errorCells: newErrors,
          );
          // Error cells auto-clear after delay (handled in UI)
          return;
        }
        newCells[row][col] = CellState.filled;
      }
    } else {
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

  // --- Hint System ---

  void enterHintMode() {
    if (state.isComplete) return;
    state = state.copyWith(isHintMode: true);
  }

  void exitHintMode() {
    state = state.copyWith(isHintMode: false);
  }

  /// Reveal a single cell. Returns true if hint was applied.
  bool useHintOnCell(int row, int col) {
    if (!state.isHintMode) return false;
    if (state.cells[row][col] == CellState.filled ||
        state.cells[row][col] == CellState.revealed) {
      return false;
    }

    final newCells = _copyCells();
    if (state.isCellCorrect(row, col)) {
      newCells[row][col] = CellState.revealed;
    } else {
      // Cell should be empty — mark it
      newCells[row][col] = CellState.marked;
    }

    final newState = state.copyWith(
      cells: newCells,
      hintsUsed: state.hintsUsed + 1,
      isHintMode: false,
    );

    if (newState.checkComplete) {
      state = newState.copyWith(isComplete: true);
    } else {
      state = newState;
    }
    return true;
  }

  // --- Error clearing ---

  void clearErrors() {
    if (state.errorCells.isEmpty) return;
    state = state.copyWith(errorCells: {});
  }

  // --- Utilities ---

  void toggleMode() {
    state = state.copyWith(
      inputMode: state.inputMode == InputMode.fill
          ? InputMode.mark
          : InputMode.fill,
    );
  }

  void restoreLives() {
    state = state.copyWith(livesRemaining: 3);
  }

  void resetPuzzle() {
    state = NonogramState.initial(state.puzzle);
  }

  List<List<CellState>> _copyCells() =>
      state.cells.map((r) => List<CellState>.from(r)).toList();

  static NonogramPuzzle _samplePuzzle() {
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
