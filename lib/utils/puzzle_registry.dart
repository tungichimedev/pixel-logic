import '../models/nonogram_puzzle.dart';
import '../models/puzzle_pack.dart';
import 'sample_puzzles.dart';

class PuzzleRegistry {
  static final List<PuzzlePack> packs = [
    PuzzlePack(
      id: 'animals',
      name: 'Animals',
      emoji: '\u{1F431}',
      puzzles: _animalsPuzzles,
    ),
    PuzzlePack(
      id: 'space',
      name: 'Space',
      emoji: '\u{1F680}',
      puzzles: _spacePuzzles,
      unlockRequirement: 3, // complete 3 animals puzzles
    ),
  ];

  static NonogramPuzzle? findById(String id) {
    for (final pack in packs) {
      for (final puzzle in pack.puzzles) {
        if (puzzle.id == id) return puzzle;
      }
    }
    return null;
  }

  static PuzzlePack? findPackById(String id) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  static NonogramPuzzle? nextPuzzle(String currentId) {
    for (final pack in packs) {
      for (int i = 0; i < pack.puzzles.length; i++) {
        if (pack.puzzles[i].id == currentId && i + 1 < pack.puzzles.length) {
          return pack.puzzles[i + 1];
        }
      }
    }
    return null;
  }

  static final _animalsPuzzles = [
    SamplePuzzles.heart5x5,
    SamplePuzzles.star5x5,
    SamplePuzzles.arrow5x5,
    NonogramPuzzle.fromPixelGrid(
      id: 'fish_5x5', title: 'Fish', packId: 'animals', orderIndex: 3,
      grid: [
        [0, 0, 1, 0, 0],
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
        [0, 0, 1, 0, 0],
      ],
      parTimeSeconds: 60, difficulty: 1,
    ),
    NonogramPuzzle.fromPixelGrid(
      id: 'tree_5x5', title: 'Tree', packId: 'animals', orderIndex: 4,
      grid: [
        [0, 0, 1, 0, 0],
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
        [0, 0, 1, 0, 0],
      ],
      parTimeSeconds: 60, difficulty: 1,
    ),
    SamplePuzzles.cat10x10,
  ];

  static final _spacePuzzles = [
    SamplePuzzles.rocket10x10,
    NonogramPuzzle.fromPixelGrid(
      id: 'planet_5x5', title: 'Planet', packId: 'space', orderIndex: 1,
      grid: [
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
      ],
      parTimeSeconds: 45, difficulty: 1,
    ),
    NonogramPuzzle.fromPixelGrid(
      id: 'ufo_5x5', title: 'UFO', packId: 'space', orderIndex: 2,
      grid: [
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 1, 0, 1, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0],
      ],
      parTimeSeconds: 60, difficulty: 1,
    ),
  ];
}
