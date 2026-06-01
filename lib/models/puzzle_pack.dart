import 'nonogram_puzzle.dart';

class PuzzlePack {
  final String id;
  final String name;
  final String emoji;
  final List<NonogramPuzzle> puzzles;
  final int unlockRequirement; // puzzles completed in previous pack
  final bool locked;

  const PuzzlePack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.puzzles,
    this.unlockRequirement = 0,
    this.locked = false,
  });
}

class PuzzleResult {
  final String puzzleId;
  final int starsEarned;
  final int timeSeconds;
  final int score;
  final int mistakes;

  const PuzzleResult({
    required this.puzzleId,
    required this.starsEarned,
    required this.timeSeconds,
    required this.score,
    required this.mistakes,
  });

  Map<String, dynamic> toJson() => {
        'puzzleId': puzzleId,
        'starsEarned': starsEarned,
        'timeSeconds': timeSeconds,
        'score': score,
        'mistakes': mistakes,
      };

  factory PuzzleResult.fromJson(Map<String, dynamic> json) => PuzzleResult(
        puzzleId: json['puzzleId'] as String,
        starsEarned: json['starsEarned'] as int,
        timeSeconds: json['timeSeconds'] as int,
        score: json['score'] as int,
        mistakes: json['mistakes'] as int,
      );
}
