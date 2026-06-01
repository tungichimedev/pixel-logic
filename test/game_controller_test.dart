import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_logic/models/nonogram_puzzle.dart';
import 'package:pixel_logic/models/nonogram_state.dart';

void main() {
  late NonogramPuzzle puzzle;

  setUp(() {
    puzzle = NonogramPuzzle.fromPixelGrid(
      id: 'test',
      title: 'Test Heart',
      packId: 'test',
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
  });

  group('NonogramPuzzle', () {
    test('fromPixelGrid derives correct row clues', () {
      expect(puzzle.rowClues[0].runs, [1, 1]);
      expect(puzzle.rowClues[1].runs, [5]);
      expect(puzzle.rowClues[2].runs, [5]);
      expect(puzzle.rowClues[3].runs, [3]);
      expect(puzzle.rowClues[4].runs, [1]);
    });

    test('fromPixelGrid derives correct column clues', () {
      expect(puzzle.colClues[0].runs, [2]);
      expect(puzzle.colClues[1].runs, [4]);
      expect(puzzle.colClues[2].runs, [4]);
      expect(puzzle.colClues[3].runs, [4]);
      expect(puzzle.colClues[4].runs, [2]);
    });

    test('empty row produces empty clue', () {
      final p = NonogramPuzzle.fromPixelGrid(
        id: 'empty', title: 'Empty', packId: 'test',
        grid: [[0, 0, 0], [1, 1, 1], [0, 0, 0]],
        parTimeSeconds: 30, difficulty: 1,
      );
      expect(p.rowClues[0].runs, isEmpty);
      expect(p.rowClues[1].runs, [3]);
      expect(p.rowClues[2].runs, isEmpty);
    });

    test('alternating pattern clues', () {
      final p = NonogramPuzzle.fromPixelGrid(
        id: 'alt', title: 'Alt', packId: 'test',
        grid: [[1, 0, 1, 0, 1]],
        parTimeSeconds: 30, difficulty: 1,
      );
      expect(p.rowClues[0].runs, [1, 1, 1]);
    });

    test('gridSize is correct', () {
      expect(puzzle.gridSize, 5);
    });

    test('minLength calculation', () {
      // [1, 1] needs at least 3 cells: X_X
      expect(puzzle.rowClues[0].minLength, 3);
      // [5] needs exactly 5
      expect(puzzle.rowClues[1].minLength, 5);
      // [3] needs exactly 3
      expect(puzzle.rowClues[3].minLength, 3);
    });
  });

  group('NonogramState', () {
    test('initial state has all empty cells', () {
      final state = NonogramState.initial(puzzle);
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          expect(state.cells[r][c], CellState.empty);
        }
      }
    });

    test('initial state has 3 lives', () {
      final state = NonogramState.initial(puzzle);
      expect(state.livesRemaining, 3);
    });

    test('isCellCorrect checks solution', () {
      final state = NonogramState.initial(puzzle);
      expect(state.isCellCorrect(0, 0), false); // solution[0][0] = 0
      expect(state.isCellCorrect(0, 1), true);  // solution[0][1] = 1
      expect(state.isCellCorrect(1, 0), true);  // solution[1][0] = 1
    });

    test('isRowSatisfied detects completed rows', () {
      var state = NonogramState.initial(puzzle);
      // Row 4 needs only cell [4][2] filled
      final cells = state.cells.map((r) => List<CellState>.from(r)).toList();
      cells[4][2] = CellState.filled;
      state = state.copyWith(cells: cells);
      expect(state.isRowSatisfied(4), true);
      expect(state.isRowSatisfied(0), false);
    });

    test('checkComplete returns false when incomplete', () {
      final state = NonogramState.initial(puzzle);
      expect(state.checkComplete, false);
    });

    test('checkComplete returns true when all cells correct', () {
      var state = NonogramState.initial(puzzle);
      final cells = state.cells.map((r) => List<CellState>.from(r)).toList();
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          if (puzzle.solution[r][c] > 0) {
            cells[r][c] = CellState.filled;
          }
        }
      }
      state = state.copyWith(cells: cells);
      expect(state.checkComplete, true);
    });

    test('revealed cells count as filled for satisfaction', () {
      var state = NonogramState.initial(puzzle);
      final cells = state.cells.map((r) => List<CellState>.from(r)).toList();
      // Fill row 4 with revealed instead of filled
      cells[4][2] = CellState.revealed;
      state = state.copyWith(cells: cells);
      expect(state.isRowSatisfied(4), true);
    });

    test('copyWith preserves unchanged fields', () {
      final state = NonogramState.initial(puzzle);
      final updated = state.copyWith(livesRemaining: 2);
      expect(updated.livesRemaining, 2);
      expect(updated.hintsUsed, 0);
      expect(updated.mistakes, 0);
      expect(updated.isComplete, false);
    });
  });
}
