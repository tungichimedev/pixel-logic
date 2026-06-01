import '../models/nonogram_puzzle.dart';
import '../models/puzzle_pack.dart';
import 'sample_puzzles.dart';

class PuzzleRegistry {
  static final List<PuzzlePack> packs = [
    PuzzlePack(
      id: 'animals',
      name: 'Animals',
      emoji: '\u{1F431}',
      puzzles: SamplePuzzles.allAnimals,
    ),
    PuzzlePack(
      id: 'space',
      name: 'Space',
      emoji: '\u{1F680}',
      puzzles: SamplePuzzles.allSpace,
      unlockRequirement: 5,
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
}
