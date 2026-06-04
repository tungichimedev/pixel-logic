import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nonogram_puzzle.dart';
import '../utils/sample_puzzles.dart';
import 'progress_controller.dart';

class DailyState {
  final NonogramPuzzle puzzle;
  final String dateKey;
  final bool completed;
  final int? bestTimeSeconds;

  const DailyState({
    required this.puzzle,
    required this.dateKey,
    this.completed = false,
    this.bestTimeSeconds,
  });

  DailyState copyWith({bool? completed, int? bestTimeSeconds}) => DailyState(
        puzzle: puzzle,
        dateKey: dateKey,
        completed: completed ?? this.completed,
        bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      );
}

class DailyController extends Notifier<DailyState> {
  static final _dailyPool = [
    ...SamplePuzzles.allAnimals.where((p) => p.gridSize == 10),
    ...SamplePuzzles.allSpace.where((p) => p.gridSize == 10),
    // Add 5x5 puzzles too for variety
    ...SamplePuzzles.allAnimals.where((p) => p.gridSize == 5),
    ...SamplePuzzles.allSpace.where((p) => p.gridSize == 5),
  ];

  @override
  DailyState build() {
    final dateKey = _todayKey();
    final puzzle = _puzzleForDate(dateKey);
    _loadFromDisk(dateKey);
    return DailyState(puzzle: puzzle, dateKey: dateKey);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  NonogramPuzzle _puzzleForDate(String dateKey) {
    final hash = dateKey.hashCode.abs();
    final index = hash % _dailyPool.length;
    final base = _dailyPool[index];
    // Create a copy with a unique daily ID
    return NonogramPuzzle.fromPixelGrid(
      id: 'daily_$dateKey',
      title: 'Daily ${base.title}',
      packId: 'daily',
      grid: base.solution,
      parTimeSeconds: base.parTimeSeconds,
      difficulty: base.difficulty,
      colorPalette: base.colorPalette,
    );
  }

  Future<void> _loadFromDisk(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('daily_$dateKey');
    if (json != null) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      state = state.copyWith(
        completed: data['completed'] as bool? ?? false,
        bestTimeSeconds: data['bestTime'] as int?,
      );
    }
  }

  Future<void> completeDaily(int timeSeconds) async {
    if (state.completed) return; // Already completed, no double reward

    final better = state.bestTimeSeconds == null || timeSeconds < state.bestTimeSeconds!;
    state = state.copyWith(
      completed: true,
      bestTimeSeconds: better ? timeSeconds : state.bestTimeSeconds,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_${state.dateKey}', jsonEncode({
      'completed': true,
      'bestTime': state.bestTimeSeconds,
    }));

    // Award daily sparks via progress controller (write-before-grant done inside)
    ref.read(progressProvider.notifier).claimDailyReward();
  }
}

final dailyProvider =
    NotifierProvider<DailyController, DailyState>(DailyController.new);
