import '../models/nonogram_puzzle.dart';

class SamplePuzzles {
  // === ANIMALS PACK (5x5) ===

  static final heart5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_01', title: 'Heart', packId: 'animals', orderIndex: 0,
    grid: [
      [0, 1, 0, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
    ],
    parTimeSeconds: 60, difficulty: 1,
  );

  static final star5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_02', title: 'Star', packId: 'animals', orderIndex: 1,
    grid: [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 0, 1, 0],
      [1, 0, 0, 0, 1],
    ],
    parTimeSeconds: 90, difficulty: 1,
  );

  static final arrow5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_03', title: 'Arrow', packId: 'animals', orderIndex: 2,
    grid: [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 0, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 0, 0],
      [0, 0, 1, 0, 0],
    ],
    parTimeSeconds: 60, difficulty: 1,
  );

  static final cross5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_04', title: 'Cross', packId: 'animals', orderIndex: 3,
    grid: [
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [1, 1, 1, 1, 1],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
    ],
    parTimeSeconds: 45, difficulty: 1,
  );

  static final diamond5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_05', title: 'Diamond', packId: 'animals', orderIndex: 4,
    grid: [
      [0, 0, 1, 0, 0],
      [0, 1, 0, 1, 0],
      [1, 0, 0, 0, 1],
      [0, 1, 0, 1, 0],
      [0, 0, 1, 0, 0],
    ],
    parTimeSeconds: 90, difficulty: 1,
  );

  static final mushroom5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_06', title: 'Mushroom', packId: 'animals', orderIndex: 5,
    grid: [
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [0, 1, 1, 1, 0],
    ],
    parTimeSeconds: 60, difficulty: 1,
  );

  static final house5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_07', title: 'House', packId: 'animals', orderIndex: 6,
    grid: [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 0, 1, 0, 1],
      [1, 1, 1, 1, 1],
    ],
    parTimeSeconds: 60, difficulty: 1,
  );

  // === ANIMALS PACK (10x10) ===

  static final cat10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_08', title: 'Cat', packId: 'animals', orderIndex: 7,
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
    parTimeSeconds: 300, difficulty: 2,
  );

  static final butterfly10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_09', title: 'Butterfly', packId: 'animals', orderIndex: 8,
    grid: [
      [1, 1, 0, 0, 0, 0, 0, 0, 1, 1],
      [1, 1, 1, 0, 0, 0, 0, 1, 1, 1],
      [1, 1, 1, 1, 0, 0, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 0, 0, 0, 0, 0, 0, 1, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    ],
    parTimeSeconds: 300, difficulty: 2,
  );

  static final flower10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'animals_10', title: 'Flower', packId: 'animals', orderIndex: 9,
    grid: [
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
      [0, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    ],
    parTimeSeconds: 240, difficulty: 2,
  );

  // === SPACE PACK ===

  static final rocket10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'space_01', title: 'Rocket', packId: 'space', orderIndex: 0,
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
    parTimeSeconds: 300, difficulty: 2,
  );

  static final planet5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'space_02', title: 'Planet', packId: 'space', orderIndex: 1,
    grid: [
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
    ],
    parTimeSeconds: 45, difficulty: 1,
  );

  static final ufo5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'space_03', title: 'UFO', packId: 'space', orderIndex: 2,
    grid: [
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 0, 1, 0],
      [0, 0, 1, 0, 0],
      [0, 0, 0, 0, 0],
    ],
    parTimeSeconds: 60, difficulty: 1,
  );

  static final moon5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'space_04', title: 'Moon', packId: 'space', orderIndex: 3,
    grid: [
      [0, 1, 1, 0, 0],
      [1, 1, 0, 0, 0],
      [1, 1, 0, 0, 0],
      [1, 1, 0, 0, 0],
      [0, 1, 1, 0, 0],
    ],
    parTimeSeconds: 60, difficulty: 1,
  );

  static final comet5x5 = NonogramPuzzle.fromPixelGrid(
    id: 'space_05', title: 'Comet', packId: 'space', orderIndex: 4,
    grid: [
      [0, 0, 0, 0, 1],
      [0, 0, 0, 1, 1],
      [1, 0, 1, 1, 0],
      [0, 1, 1, 0, 0],
      [1, 1, 0, 0, 0],
    ],
    parTimeSeconds: 90, difficulty: 1,
  );

  static final satellite10x10 = NonogramPuzzle.fromPixelGrid(
    id: 'space_06', title: 'Satellite', packId: 'space', orderIndex: 5,
    grid: [
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0, 0, 0],
      [0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 1, 1, 1, 0, 0],
      [0, 0, 0, 0, 0, 1, 1, 1, 0, 0],
      [0, 0, 0, 0, 0, 0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    ],
    parTimeSeconds: 300, difficulty: 2,
  );

  static final allAnimals = [
    heart5x5, star5x5, arrow5x5, cross5x5, diamond5x5,
    mushroom5x5, house5x5, cat10x10, butterfly10x10, flower10x10,
  ];

  static final allSpace = [
    rocket10x10, planet5x5, ufo5x5, moon5x5, comet5x5, satellite10x10,
  ];

  static final all = [...allAnimals, ...allSpace];
}
