import 'dart:async';
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
  final int sparkReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.sparkReward = 15,
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
      sparkReward: 15,
    ),
    Achievement(
      id: 'ten_puzzles',
      title: 'Dedicated',
      description: 'Complete 10 puzzles',
      icon: '\u{1F3C6}',
      target: 10,
      sparkReward: 30,
    ),
    Achievement(
      id: 'perfect_solve',
      title: 'Perfectionist',
      description: 'Complete a puzzle with zero errors',
      icon: '\u{2B50}',
      target: 1,
      sparkReward: 15,
    ),
    Achievement(
      id: 'streak_master',
      title: 'Streak Master',
      description: '7-day daily streak',
      icon: '\u{1F525}',
      target: 7,
      sparkReward: 50,
    ),
    Achievement(
      id: 'collector',
      title: 'Collector',
      description: 'Complete all puzzles in 1 pack',
      icon: '\u{1F3A8}',
      target: 1,
      sparkReward: 50,
    ),
  ];

  Completer<void>? _loadCompleter;
  Future<void> get loaded => _loadCompleter?.future ?? Future.value();

  @override
  AchievementState build() {
    _loadCompleter = Completer<void>();
    _loadFromDisk().then((_) {
      if (!_loadCompleter!.isCompleted) _loadCompleter!.complete();
    });
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
    final justUnlockedList = <String>[];

    // First solve
    newProgress['first_solve'] = progressState.results.length;
    if (progressState.results.isNotEmpty && !newUnlocked.contains('first_solve')) {
      newUnlocked.add('first_solve');
      justUnlockedList.add('first_solve');
    }

    // Ten puzzles
    newProgress['ten_puzzles'] = progressState.results.length;
    if (progressState.results.length >= 10 && !newUnlocked.contains('ten_puzzles')) {
      newUnlocked.add('ten_puzzles');
      justUnlockedList.add('ten_puzzles');
    }

    // Perfect solve
    if (mistakes == 0) {
      newProgress['perfect_solve'] = 1;
      if (!newUnlocked.contains('perfect_solve')) {
        newUnlocked.add('perfect_solve');
        justUnlockedList.add('perfect_solve');
      }
    }

    state = state.copyWith(progress: newProgress, unlocked: newUnlocked);
    await _saveToDisk();

    // Award sparks for each newly unlocked achievement
    for (final id in justUnlockedList) {
      final achievement = achievements.firstWhere((a) => a.id == id);
      ref.read(progressProvider.notifier).addSparks(achievement.sparkReward);
    }

    // Show popup for the first newly unlocked achievement
    if (justUnlockedList.isNotEmpty) {
      _lastUnlocked = justUnlockedList.first;
    }
  }

  /// Check streak achievement. Called from login streak logic.
  Future<void> checkStreak(int streakDay) async {
    final newProgress = Map<String, int>.from(state.progress);
    final newUnlocked = Set<String>.from(state.unlocked);

    newProgress['streak_master'] = streakDay;
    if (streakDay >= 7 && !newUnlocked.contains('streak_master')) {
      newUnlocked.add('streak_master');
      state = state.copyWith(progress: newProgress, unlocked: newUnlocked);
      await _saveToDisk();
      ref.read(progressProvider.notifier).addSparks(
        achievements.firstWhere((a) => a.id == 'streak_master').sparkReward,
      );
      _lastUnlocked = 'streak_master';
    } else {
      state = state.copyWith(progress: newProgress);
      await _saveToDisk();
    }
  }

  /// Check collector achievement (all puzzles in a pack completed).
  Future<void> checkPackComplete(String packId, int completed, int total) async {
    if (completed < total) return;

    final newProgress = Map<String, int>.from(state.progress);
    final newUnlocked = Set<String>.from(state.unlocked);

    newProgress['collector'] = 1;
    if (!newUnlocked.contains('collector')) {
      newUnlocked.add('collector');
      state = state.copyWith(progress: newProgress, unlocked: newUnlocked);
      await _saveToDisk();
      ref.read(progressProvider.notifier).addSparks(
        achievements.firstWhere((a) => a.id == 'collector').sparkReward,
      );
      _lastUnlocked = 'collector';
    } else {
      state = state.copyWith(progress: newProgress);
      await _saveToDisk();
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
