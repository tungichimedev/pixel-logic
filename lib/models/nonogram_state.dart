import 'nonogram_puzzle.dart';

enum CellState { empty, filled, marked, revealed }

enum InputMode { fill, mark }

class NonogramState {
  final NonogramPuzzle puzzle;
  final List<List<CellState>> cells;
  final int livesRemaining;
  final int hintsUsed;
  final int mistakes;
  final bool isComplete;
  final bool puristMode;
  final InputMode inputMode;
  final bool isHintMode;
  final Set<(int, int)> errorCells; // Cells that just errored (flash red)

  const NonogramState({
    required this.puzzle,
    required this.cells,
    this.livesRemaining = 3,
    this.hintsUsed = 0,
    this.mistakes = 0,
    this.isComplete = false,
    this.puristMode = false,
    this.inputMode = InputMode.fill,
    this.isHintMode = false,
    this.errorCells = const {},
  });

  factory NonogramState.initial(NonogramPuzzle puzzle) {
    final cells = List.generate(
      puzzle.gridSize,
      (_) => List.filled(puzzle.gridSize, CellState.empty),
    );
    return NonogramState(puzzle: puzzle, cells: cells);
  }

  bool isCellCorrect(int row, int col) => puzzle.solution[row][col] > 0;

  bool isRowSatisfied(int row) {
    final filledCells = cells[row]
        .map((c) => c == CellState.filled || c == CellState.revealed)
        .toList();
    return _runsMatch(filledCells, puzzle.rowClues[row].runs);
  }

  bool isColSatisfied(int col) {
    final filledCells = List.generate(
      puzzle.gridSize,
      (row) =>
          cells[row][col] == CellState.filled ||
          cells[row][col] == CellState.revealed,
    );
    return _runsMatch(filledCells, puzzle.colClues[col].runs);
  }

  bool _runsMatch(List<bool> cells, List<int> expectedRuns) {
    final actualRuns = <int>[];
    int current = 0;
    for (final c in cells) {
      if (c) {
        current++;
      } else if (current > 0) {
        actualRuns.add(current);
        current = 0;
      }
    }
    if (current > 0) actualRuns.add(current);
    if (actualRuns.length != expectedRuns.length) return false;
    for (int i = 0; i < actualRuns.length; i++) {
      if (actualRuns[i] != expectedRuns[i]) return false;
    }
    return true;
  }

  bool get checkComplete {
    for (int r = 0; r < puzzle.gridSize; r++) {
      if (!isRowSatisfied(r)) return false;
    }
    for (int c = 0; c < puzzle.gridSize; c++) {
      if (!isColSatisfied(c)) return false;
    }
    return true;
  }

  NonogramState copyWith({
    List<List<CellState>>? cells,
    int? livesRemaining,
    int? hintsUsed,
    int? mistakes,
    bool? isComplete,
    InputMode? inputMode,
    bool? isHintMode,
    Set<(int, int)>? errorCells,
  }) =>
      NonogramState(
        puzzle: puzzle,
        cells: cells ?? this.cells,
        livesRemaining: livesRemaining ?? this.livesRemaining,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        mistakes: mistakes ?? this.mistakes,
        isComplete: isComplete ?? this.isComplete,
        puristMode: puristMode,
        inputMode: inputMode ?? this.inputMode,
        isHintMode: isHintMode ?? this.isHintMode,
        errorCells: errorCells ?? this.errorCells,
      );
}
