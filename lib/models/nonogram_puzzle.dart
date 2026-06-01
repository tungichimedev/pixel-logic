typedef PixelGrid = List<List<int>>; // 0 = empty, 1+ = color palette index

class NonogramClue {
  final List<int> runs;

  const NonogramClue(this.runs);

  int get minLength =>
      runs.isEmpty ? 0 : runs.reduce((a, b) => a + b) + runs.length - 1;

  bool get isEmpty => runs.isEmpty;

  @override
  String toString() => runs.join(' ');
}

class NonogramPuzzle {
  final String id;
  final String title;
  final String packId;
  final int gridSize;
  final PixelGrid solution;
  final List<NonogramClue> rowClues;
  final List<NonogramClue> colClues;
  final int parTimeSeconds;
  final int difficulty;
  final int orderIndex;
  final List<int> colorPalette; // ARGB values

  const NonogramPuzzle({
    required this.id,
    required this.title,
    required this.packId,
    required this.gridSize,
    required this.solution,
    required this.rowClues,
    required this.colClues,
    required this.parTimeSeconds,
    required this.difficulty,
    this.orderIndex = 0,
    this.colorPalette = const [0xFF4488FF],
  });

  static NonogramPuzzle fromPixelGrid({
    required String id,
    required String title,
    required String packId,
    required PixelGrid grid,
    required int parTimeSeconds,
    required int difficulty,
    int orderIndex = 0,
    List<int> colorPalette = const [0xFF4488FF],
  }) {
    final size = grid.length;
    final rowClues =
        grid.map((row) => NonogramClue(_runsFor(row))).toList();
    final colClues = List.generate(size, (col) {
      final colCells = List.generate(size, (row) => grid[row][col]);
      return NonogramClue(_runsFor(colCells));
    });
    return NonogramPuzzle(
      id: id,
      title: title,
      packId: packId,
      gridSize: size,
      solution: grid,
      rowClues: rowClues,
      colClues: colClues,
      parTimeSeconds: parTimeSeconds,
      difficulty: difficulty,
      orderIndex: orderIndex,
      colorPalette: colorPalette,
    );
  }

  static List<int> _runsFor(List<int> cells) {
    final runs = <int>[];
    int current = 0;
    for (final cell in cells) {
      if (cell > 0) {
        current++;
      } else if (current > 0) {
        runs.add(current);
        current = 0;
      }
    }
    if (current > 0) runs.add(current);
    return runs;
  }

  @override
  String toString() => 'NonogramPuzzle($id, ${gridSize}x$gridSize)';
}
