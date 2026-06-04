import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/puzzle_pack.dart';

/// Spark reward constants for the game economy.
class SparkRewards {
  SparkRewards._();
  static const int complete5x5 = 15;
  static const int complete10x10 = 40;
  static const int threeStarBonus = 10; // first time only
  static const int zeroErrorBonus = 5;
  static const int dailyPuzzle = 50;
  static const int rewardedAd = 30;
  static const int cellHintCost = 30;
  static const int rowHintCost = 80;
  static const int extraLifeCost = 40;
  static const int packComplete = 100;
  static const int maxSparks = 99999;
  static const int maxLives = 3;
  static const int lifeRegenMinutes = 30;
  static const int maxRewardedAdsPerDay = 3;

  /// Login streak rewards by day (1-indexed). Day 7+ = 50.
  static int streakReward(int day) {
    const rewards = [0, 10, 15, 20, 25, 30, 40, 50];
    if (day <= 0) return 0;
    if (day >= rewards.length) return 50;
    return rewards[day];
  }
}

class ProgressState {
  final Map<String, PuzzleResult> results;
  final int totalXP;
  final int sparks;
  final int lives;
  final DateTime? lastLifeLostAt;
  final String? lastLoginDate; // yyyy-MM-dd
  final int streakDay;
  final bool streakFreezeAvailable;
  final bool dailyRewardClaimed;
  final Set<String> packRewardsClaimed;
  final Set<String> threeStarBonusClaimed; // puzzle IDs that already got the 3-star bonus
  final int rewardedAdsToday;
  final String? rewardedAdsDate; // track which day the counter is for

  const ProgressState({
    this.results = const {},
    this.totalXP = 0,
    this.sparks = 0,
    this.lives = 3,
    this.lastLifeLostAt,
    this.lastLoginDate,
    this.streakDay = 0,
    this.streakFreezeAvailable = false,
    this.dailyRewardClaimed = false,
    this.packRewardsClaimed = const {},
    this.threeStarBonusClaimed = const {},
    this.rewardedAdsToday = 0,
    this.rewardedAdsDate,
  });

  int get level => totalXP ~/ 200;

  bool get canWatchRewardedAd {
    final today = _todayKey();
    if (rewardedAdsDate != today) return true; // new day, counter resets
    return rewardedAdsToday < SparkRewards.maxRewardedAdsPerDay;
  }

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
    int? sparks,
    int? lives,
    DateTime? lastLifeLostAt,
    bool clearLastLifeLostAt = false,
    String? lastLoginDate,
    int? streakDay,
    bool? streakFreezeAvailable,
    bool? dailyRewardClaimed,
    Set<String>? packRewardsClaimed,
    Set<String>? threeStarBonusClaimed,
    int? rewardedAdsToday,
    String? rewardedAdsDate,
  }) => ProgressState(
    results: results ?? this.results,
    totalXP: totalXP ?? this.totalXP,
    sparks: sparks ?? this.sparks,
    lives: lives ?? this.lives,
    lastLifeLostAt: clearLastLifeLostAt ? null : (lastLifeLostAt ?? this.lastLifeLostAt),
    lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    streakDay: streakDay ?? this.streakDay,
    streakFreezeAvailable: streakFreezeAvailable ?? this.streakFreezeAvailable,
    dailyRewardClaimed: dailyRewardClaimed ?? this.dailyRewardClaimed,
    packRewardsClaimed: packRewardsClaimed ?? this.packRewardsClaimed,
    threeStarBonusClaimed: threeStarBonusClaimed ?? this.threeStarBonusClaimed,
    rewardedAdsToday: rewardedAdsToday ?? this.rewardedAdsToday,
    rewardedAdsDate: rewardedAdsDate ?? this.rewardedAdsDate,
  );
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class ProgressController extends Notifier<ProgressState> {
  Completer<void>? _loadCompleter;

  /// Wait for disk load to complete before calling economy methods.
  Future<void> get loaded => _loadCompleter?.future ?? Future.value();

  @override
  ProgressState build() {
    _loadCompleter = Completer<void>();
    _loadFromDisk().then((_) {
      if (!_loadCompleter!.isCompleted) _loadCompleter!.complete();
    });
    return const ProgressState();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString('puzzle_results');
    final xp = prefs.getInt('total_xp') ?? 0;
    final sparks = prefs.getInt('sparks') ?? 0;
    final lives = prefs.getInt('lives') ?? 3;
    final lastLifeLostMs = prefs.getInt('last_life_lost_at');
    final lastLoginDate = prefs.getString('last_login_date');
    final streakDay = prefs.getInt('streak_day') ?? 0;
    final streakFreezeAvailable = prefs.getBool('streak_freeze_available') ?? false;
    final dailyRewardClaimed = prefs.getBool('daily_reward_claimed') ?? false;
    final packRewardsJson = prefs.getStringList('pack_rewards_claimed') ?? [];
    final threeStarJson = prefs.getStringList('three_star_bonus_claimed') ?? [];
    final rewardedAdsToday = prefs.getInt('rewarded_ads_today') ?? 0;
    final rewardedAdsDate = prefs.getString('rewarded_ads_date');

    Map<String, PuzzleResult> results = {};
    if (resultsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(resultsJson);
      results = decoded.map(
        (key, value) => MapEntry(key, PuzzleResult.fromJson(value as Map<String, dynamic>)),
      );
    }

    state = ProgressState(
      results: results,
      totalXP: xp,
      sparks: sparks,
      lives: lives.clamp(0, SparkRewards.maxLives),
      lastLifeLostAt: lastLifeLostMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastLifeLostMs)
          : null,
      lastLoginDate: lastLoginDate,
      streakDay: streakDay,
      streakFreezeAvailable: streakFreezeAvailable,
      dailyRewardClaimed: dailyRewardClaimed,
      packRewardsClaimed: packRewardsJson.toSet(),
      threeStarBonusClaimed: threeStarJson.toSet(),
      rewardedAdsToday: rewardedAdsToday,
      rewardedAdsDate: rewardedAdsDate,
    );

    // Regenerate lives on load
    _regenLives();
  }

  // --- Sparks ---

  void addSparks(int amount) {
    if (amount <= 0) return;
    final newSparks = (state.sparks + amount).clamp(0, SparkRewards.maxSparks);
    state = state.copyWith(sparks: newSparks);
    _saveToDisk();
  }

  /// Returns true if sparks were spent, false if insufficient.
  bool spendSparks(int amount) {
    if (amount <= 0) return true;
    if (state.sparks < amount) return false;
    state = state.copyWith(sparks: state.sparks - amount);
    _saveToDisk();
    return true;
  }

  // --- Lives ---

  void loseLife() {
    if (state.lives <= 0) return;
    final newLives = state.lives - 1;
    state = state.copyWith(
      lives: newLives,
      lastLifeLostAt: DateTime.now(),
    );
    _saveToDisk();
  }

  /// Buy an extra life with sparks. Returns true on success.
  bool buyLife() {
    if (state.lives >= SparkRewards.maxLives) return false;
    if (!spendSparks(SparkRewards.extraLifeCost)) return false;
    state = state.copyWith(
      lives: (state.lives + 1).clamp(0, SparkRewards.maxLives),
    );
    _saveToDisk();
    return true;
  }

  void _regenLives() {
    if (state.lives >= SparkRewards.maxLives) return;
    if (state.lastLifeLostAt == null) return;

    final elapsed = DateTime.now().difference(state.lastLifeLostAt!);
    final livesRecovered = elapsed.inMinutes ~/ SparkRewards.lifeRegenMinutes;
    if (livesRecovered <= 0) return;

    final newLives = (state.lives + livesRecovered).clamp(0, SparkRewards.maxLives);
    state = state.copyWith(
      lives: newLives,
      clearLastLifeLostAt: newLives >= SparkRewards.maxLives,
      lastLifeLostAt: newLives < SparkRewards.maxLives ? state.lastLifeLostAt : null,
    );
    _saveToDisk();
  }

  /// Call on app open to regen lives.
  void regenLives() => _regenLives();

  /// Time until next life regeneration, or null if lives are full.
  Duration? get nextLifeRegenIn {
    if (state.lives >= SparkRewards.maxLives) return null;
    if (state.lastLifeLostAt == null) return null;
    final elapsed = DateTime.now().difference(state.lastLifeLostAt!);
    final nextRegenAt = Duration(minutes: SparkRewards.lifeRegenMinutes);
    final timeSinceLastRegen = Duration(
      minutes: elapsed.inMinutes % SparkRewards.lifeRegenMinutes,
      seconds: elapsed.inSeconds % 60,
    );
    final remaining = nextRegenAt - timeSinceLastRegen;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // --- Login Streak ---

  /// Check and claim login streak. Call once per app open.
  void checkLoginStreak() {
    final today = _todayKey();
    if (state.lastLoginDate == today) return; // already checked today

    final yesterday = _yesterdayKey();
    int newStreak;
    bool newFreezeAvailable = state.streakFreezeAvailable;

    if (state.lastLoginDate == yesterday) {
      // Consecutive day
      newStreak = state.streakDay + 1;
    } else if (state.lastLoginDate != null && state.lastLoginDate != today) {
      // Missed day(s) — check gap size and freeze
      final lastDate = DateTime.tryParse(state.lastLoginDate!);
      final todayDate = DateTime.tryParse(today);
      final gapDays = (lastDate != null && todayDate != null)
          ? todayDate.difference(lastDate).inDays
          : 99;

      if (gapDays == 2 && state.streakFreezeAvailable) {
        // Missed exactly 1 day — use freeze
        newStreak = state.streakDay + 1;
        newFreezeAvailable = false;
      } else {
        // Missed 2+ days — reset streak (freeze only covers 1 day)
        newStreak = 1;
      }
    } else {
      // First ever login
      newStreak = 1;
    }

    // Earn a free streak freeze every 3-day streak
    if (newStreak > 0 && newStreak % 3 == 0 && !newFreezeAvailable) {
      newFreezeAvailable = true;
    }

    // Write-before-grant: update state BEFORE granting sparks
    state = state.copyWith(
      lastLoginDate: today,
      streakDay: newStreak,
      streakFreezeAvailable: newFreezeAvailable,
      dailyRewardClaimed: false, // reset daily reward for new day
    );
    _saveToDisk();

    // Grant streak sparks
    final reward = SparkRewards.streakReward(newStreak);
    if (reward > 0) {
      addSparks(reward);
    }
  }

  String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  // --- Daily Reward ---

  /// Claim the daily puzzle completion reward (50 sparks).
  void claimDailyReward() {
    if (state.dailyRewardClaimed) return;
    // Write-before-grant
    state = state.copyWith(dailyRewardClaimed: true);
    _saveToDisk();
    addSparks(SparkRewards.dailyPuzzle);
  }

  // --- Pack Completion Reward ---

  void claimPackReward(String packId) {
    if (state.packRewardsClaimed.contains(packId)) return;
    // Write-before-grant
    final newClaimed = Set<String>.from(state.packRewardsClaimed)..add(packId);
    state = state.copyWith(packRewardsClaimed: newClaimed);
    _saveToDisk();
    addSparks(SparkRewards.packComplete);
  }

  // --- Rewarded Ad ---

  /// Record a rewarded ad watch. Returns true if allowed.
  bool recordRewardedAd() {
    final today = _todayKey();
    int adsToday = state.rewardedAdsToday;
    if (state.rewardedAdsDate != today) {
      adsToday = 0; // new day
    }
    if (adsToday >= SparkRewards.maxRewardedAdsPerDay) return false;

    state = state.copyWith(
      rewardedAdsToday: adsToday + 1,
      rewardedAdsDate: today,
    );
    _saveToDisk();
    addSparks(SparkRewards.rewardedAd);
    return true;
  }

  // --- Puzzle Completion ---

  Future<void> completePuzzle(PuzzleResult result, {required int gridSize}) async {
    final existing = state.results[result.puzzleId];
    final isFirstCompletion = existing == null;
    // Only update if better score or first completion
    if (!isFirstCompletion && existing.score >= result.score) return;

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

    // Spark rewards (only on first completion of this puzzle)
    if (isFirstCompletion) {
      // Base reward by grid size
      final baseReward = gridSize == 5
          ? SparkRewards.complete5x5
          : SparkRewards.complete10x10;
      addSparks(baseReward);

      // Zero-error bonus
      if (result.mistakes == 0) {
        addSparks(SparkRewards.zeroErrorBonus);
      }
    }

    // 3-star bonus (first time only, even on replay)
    if (result.starsEarned >= 3 && !state.threeStarBonusClaimed.contains(result.puzzleId)) {
      final newClaimed = Set<String>.from(state.threeStarBonusClaimed)..add(result.puzzleId);
      state = state.copyWith(threeStarBonusClaimed: newClaimed);
      await _saveToDisk();
      addSparks(SparkRewards.threeStarBonus);
    }
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = jsonEncode(
      state.results.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString('puzzle_results', resultsJson);
    await prefs.setInt('total_xp', state.totalXP);
    await prefs.setInt('sparks', state.sparks);
    await prefs.setInt('lives', state.lives);
    if (state.lastLifeLostAt != null) {
      await prefs.setInt('last_life_lost_at', state.lastLifeLostAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('last_life_lost_at');
    }
    await prefs.setString('last_login_date', state.lastLoginDate ?? '');
    await prefs.setInt('streak_day', state.streakDay);
    await prefs.setBool('streak_freeze_available', state.streakFreezeAvailable);
    await prefs.setBool('daily_reward_claimed', state.dailyRewardClaimed);
    await prefs.setStringList('pack_rewards_claimed', state.packRewardsClaimed.toList());
    await prefs.setStringList('three_star_bonus_claimed', state.threeStarBonusClaimed.toList());
    await prefs.setInt('rewarded_ads_today', state.rewardedAdsToday);
    await prefs.setString('rewarded_ads_date', state.rewardedAdsDate ?? '');
  }
}

final progressProvider =
    NotifierProvider<ProgressController, ProgressState>(ProgressController.new);
