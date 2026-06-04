import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/puzzle_pack.dart';

class ProgressState {
  final Map<String, PuzzleResult> results;
  final int totalXP;

  const ProgressState({this.results = const {}, this.totalXP = 0});

  int get level => totalXP ~/ 200;

  int completedInPack(String packId) {
    return results.values.where((r) => r.puzzleId.startsWith('${packId}_')).length;
  }

  int starsInPack(String packId, List<String> puzzleIds) {
    int stars = 0;
    for (final id in puzzleIds) {
      stars += results[id]?.starsEarned ?? 0;
    }
    return stars;
  }

  ProgressState copyWith({
    Map<String, PuzzleResult>? results,
    int? totalXP,
  }) => ProgressState(
    results: results ?? this.results,
    totalXP: totalXP ?? this.totalXP,
  );
}

class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    _loadFromDisk();
    return const ProgressState();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString('puzzle_results');
    final xp = prefs.getInt('total_xp') ?? 0;

    if (resultsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(resultsJson);
      final results = decoded.map(
        (key, value) => MapEntry(key, PuzzleResult.fromJson(value as Map<String, dynamic>)),
      );
      state = ProgressState(results: results, totalXP: xp);
    }
  }

  Future<void> completePuzzle(PuzzleResult result, {required int gridSize}) async {
    final existing = state.results[result.puzzleId];
    // Only update if better score or first completion
    if (existing != null && existing.score >= result.score) return;

    final newResults = Map<String, PuzzleResult>.from(state.results);
    newResults[result.puzzleId] = result;

    // XP: 5x5=10, 10x10=30, no-error bonus +50%
    int xpGain = gridSize == 5 ? 10 : 30;
    if (result.mistakes == 0) xpGain = (xpGain * 1.5).round();

    state = state.copyWith(
      results: newResults,
      totalXP: state.totalXP + xpGain,
    );

    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = jsonEncode(
      state.results.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString('puzzle_results', resultsJson);
    await prefs.setInt('total_xp', state.totalXP);
  }
}

final progressProvider =
    NotifierProvider<ProgressController, ProgressState>(ProgressController.new);
