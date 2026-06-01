import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_controller.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
  });
}

class AchievementState {
  final Map<String, int> progress; // achievement_id -> current progress
  final Set<String> unlocked;

  const AchievementState({
    this.progress = const {},
    this.unlocked = const {},
  });

  AchievementState copyWith({Map<String, int>? progress, Set<String>? unlocked}) =>
      AchievementState(
        progress: progress ?? this.progress,
        unlocked: unlocked ?? this.unlocked,
      );
}

class AchievementsController extends Notifier<AchievementState> {
  static const achievements = [
    Achievement(
      id: 'first_solve',
      title: 'First Steps',
      description: 'Complete your first puzzle',
      icon: '\u{2705}',
      target: 1,
    ),
    Achievement(
      id: 'ten_puzzles',
      title: 'Dedicated',
      description: 'Complete 10 puzzles',
      icon: '\u{1F3C6}',
      target: 10,
    ),
    Achievement(
      id: 'perfect_solve',
      title: 'Perfectionist',
      description: 'Complete a puzzle with zero errors',
      icon: '\u{2B50}',
      target: 1,
    ),
  ];

  @override
  AchievementState build() {
    _loadFromDisk();
    return const AchievementState();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('achievements');
    if (json != null) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      state = AchievementState(
        progress: (data['progress'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        unlocked: (data['unlocked'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
      );
    }
  }

  Future<void> checkAfterPuzzle(ProgressState progressState, int mistakes) async {
    final newProgress = Map<String, int>.from(state.progress);
    final newUnlocked = Set<String>.from(state.unlocked);
    String? justUnlocked;

    // First solve
    newProgress['first_solve'] = progressState.results.length;
    if (progressState.results.isNotEmpty && !newUnlocked.contains('first_solve')) {
      newUnlocked.add('first_solve');
      justUnlocked = 'first_solve';
    }

    // Ten puzzles
    newProgress['ten_puzzles'] = progressState.results.length;
    if (progressState.results.length >= 10 && !newUnlocked.contains('ten_puzzles')) {
      newUnlocked.add('ten_puzzles');
      justUnlocked = 'ten_puzzles';
    }

    // Perfect solve
    if (mistakes == 0) {
      newProgress['perfect_solve'] = 1;
      if (!newUnlocked.contains('perfect_solve')) {
        newUnlocked.add('perfect_solve');
        justUnlocked = 'perfect_solve';
      }
    }

    state = state.copyWith(progress: newProgress, unlocked: newUnlocked);
    await _saveToDisk();

    // Show popup if just unlocked
    if (justUnlocked != null) {
      _lastUnlocked = justUnlocked;
    }
  }

  String? _lastUnlocked;
  String? consumeLastUnlocked() {
    final val = _lastUnlocked;
    _lastUnlocked = null;
    return val;
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('achievements', jsonEncode({
      'progress': state.progress,
      'unlocked': state.unlocked.toList(),
    }));
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsController, AchievementState>(AchievementsController.new);
