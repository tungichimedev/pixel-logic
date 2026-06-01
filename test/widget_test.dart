import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_logic/models/nonogram_puzzle.dart';

void main() {
  test('Clue derivation from pixel grid', () {
    final puzzle = NonogramPuzzle.fromPixelGrid(
      id: 'test',
      title: 'Heart',
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

    expect(puzzle.rowClues[0].runs, [1, 1]);
    expect(puzzle.rowClues[1].runs, [5]);
    expect(puzzle.rowClues[2].runs, [5]);
    expect(puzzle.rowClues[3].runs, [3]);
    expect(puzzle.rowClues[4].runs, [1]);

    expect(puzzle.colClues[0].runs, [2]);
    expect(puzzle.colClues[1].runs, [4]);
    expect(puzzle.colClues[2].runs, [4]);
    expect(puzzle.colClues[3].runs, [4]);
    expect(puzzle.colClues[4].runs, [2]);
  });
}
