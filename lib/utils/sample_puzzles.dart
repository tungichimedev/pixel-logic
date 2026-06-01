import '../models/nonogram_puzzle.dart';

class SamplePuzzles {
  static final heart5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'heart_5x5',
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

  static final star5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'star_5x5',
    title: 'Star',
    packId: 'animals',
    grid: [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 0, 1, 0],
      [1, 0, 0, 0, 1],
    ],
    parTimeSeconds: 90,
    difficulty: 1,
  );

  static final arrow5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'arrow_5x5',
    title: 'Arrow',
    packId: 'animals',
    grid: [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 0, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 0, 0],
      [0, 0, 1, 0, 0],
    ],
    parTimeSeconds: 60,
    difficulty: 1,
  );

  static final cat10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'cat_10x10',
    title: 'Cat',
    packId: 'animals',
    grid: [
      [1, 1, 0, 0, 0, 0, 0, 0, 1, 1],
      [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 0, 1, 1, 1, 1, 0, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [1, 0, 1, 0, 1, 1, 0, 1, 0, 1],
      [1, 0, 1, 1, 0, 0, 1, 1, 0, 1],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
    ],
    parTimeSeconds: 300,
    difficulty: 2,
  );

  static final rocket10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'rocket_10x10',
    title: 'Rocket',
    packId: 'space',
    grid: [
      [0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 0, 1, 1, 1, 1, 0, 1, 1],
      [1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
      [0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
    ],
    parTimeSeconds: 300,
    difficulty: 2,
  );

  static final all = [heart5x5, star5x5, arrow5x5, cat10x10, rocket10x10];
}
