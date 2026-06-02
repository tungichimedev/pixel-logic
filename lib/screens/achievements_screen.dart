import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/achievements_controller.dart';
import '../controllers/progress_controller.dart';
import '../utils/app_theme.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementsProvider);
    final progress = ref.watch(progressProvider);
    final allAchievements = AchievementsController.achievements;
    final unlocked = achievementState.unlocked;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      'ACHIEVEMENTS',
                      style: AppFonts.pixel(
                          fontSize: 10,
                          color: AppColors.primary,
                          letterSpacing: 2),
                    ),
                    const Spacer(),
                    Text(
                      '${unlocked.length}/${allAchievements.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              // Achievement list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allAchievements.length,
                  itemBuilder: (context, index) {
                    final achievement = allAchievements[index];
                    final isUnlocked = unlocked.contains(achievement.id);
                    final progressValue =
                        _getProgress(achievement, progress, isUnlocked);

                    return _buildAchievementCard(
                      achievement: achievement,
                      isUnlocked: isUnlocked,
                      progress: progressValue,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getProgress(
      Achievement achievement, ProgressState progress, bool unlocked) {
    if (unlocked) return 1.0;
    switch (achievement.id) {
      case 'first_steps':
        return progress.results.isEmpty ? 0.0 : 1.0;
      case 'dedicated':
        return (progress.results.length / 10).clamp(0.0, 1.0);
      case 'perfectionist':
        final perfect = progress.results.values
            .where((r) => r.starsEarned >= 3)
            .length;
        return (perfect / 30).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  Widget _buildAchievementCard({
    required Achievement achievement,
    required bool isUnlocked,
    required double progress,
  }) {
    final isInProgress = !isUnlocked && progress > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE066), Color(0xFFFF9500)],
                    )
                  : null,
              color: isUnlocked ? null : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: isUnlocked
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isUnlocked
                ? Text(achievement.icon, style: const TextStyle(fontSize: 22))
                : Icon(Icons.lock_rounded,
                    color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: isUnlocked ? AppColors.primary : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isInProgress || isUnlocked) ...[
                  const SizedBox(height: 6),
                  // Progress bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUnlocked
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [AppColors.cellFilled, const Color(0xFF6699FF)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status
          if (isUnlocked)
            const Icon(Icons.check_rounded,
                color: AppColors.satisfied, size: 20),
        ],
      ),
    );
  }
}
