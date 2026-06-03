import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/progress_controller.dart';
import '../controllers/purchase_controller.dart';
import '../services/ad_service.dart';
import '../services/consent_service.dart';
import '../utils/app_theme.dart';

final soundEnabledProvider = NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);
final hapticEnabledProvider = NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);

class _BoolNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(soundEnabledProvider);
    final hapticEnabled = ref.watch(hapticEnabledProvider);
    final progress = ref.watch(progressProvider);
    final purchases = ref.watch(purchaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'SETTINGS',
                style: AppFonts.pixel(fontSize: 12, color: AppColors.primary, letterSpacing: 2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _sectionLabel('SOUND & HAPTICS'),
                  _settingsGroup([
                    _toggleRow('Sound Effects', soundEnabled, (v) {
                      ref.read(soundEnabledProvider.notifier).set(v);
                    }),
                    _divider(),
                    _toggleRow('Haptics', hapticEnabled, (v) {
                      ref.read(hapticEnabledProvider.notifier).set(v);
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('STATS'),
                  _settingsGroup([
                    _infoRow('Puzzles Solved', '${progress.results.length}'),
                    _divider(),
                    _infoRow('Total XP', '${progress.totalXP}'),
                    _divider(),
                    _infoRow('Level', '${progress.level}'),
                    _divider(),
                    _infoRow('Total Stars',
                        '${progress.results.values.fold<int>(0, (sum, r) => sum + r.starsEarned)}'),
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('GAMEPLAY'),
                  _settingsGroup([
                    _lockedRow('Purist Mode', 'No error checking',
                        purchases.isPro ? 'ON' : 'PRO'),
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('PURCHASES'),
                  _settingsGroup([
                    _actionRow('Restore Purchases', Icons.refresh_rounded, () {
                      _handleRestore(context, ref);
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('PRIVACY'),
                  _settingsGroup([
                    _actionRow('Privacy Policy', Icons.open_in_new_rounded, () {
                      launchUrl(
                        Uri.parse('https://freelancer-landing-page.web.app/privacy'),
                        mode: LaunchMode.externalApplication,
                      );
                    }),
                    _divider(),
                    _actionRow('Manage Ad Consent', Icons.privacy_tip_rounded, () async {
                      final consent = await ConsentService.instance.requestConsent();
                      if (AdService.instance.isInitialized) {
                        // Re-init not possible, but consent state is persisted
                        // and will take effect on next app launch
                      } else {
                        await AdService.instance.initialize(consentGiven: consent);
                      }
                    }),
                    _divider(),
                    _actionRow('Delete My Data', Icons.delete_forever_rounded, () {
                      _showDeleteDialog(context);
                    }, isDestructive: true),
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('PROGRESS'),
                  _settingsGroup([
                    _actionRow('Achievements', Icons.emoji_events_rounded, () {
                      context.push('/achievements');
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('ABOUT'),
                  _settingsGroup([
                    _infoRow('Version', '1.0.0'),
                    _divider(),
                    _actionRow('Support', Icons.help_outline_rounded, () {
                      launchUrl(
                        Uri.parse('https://freelancer-landing-page.web.app/support'),
                        mode: LaunchMode.externalApplication,
                      );
                    }),
                    _divider(),
                    _actionRow('Rate App', Icons.star_rounded, () {}),
                  ]),
                  const SizedBox(height: 24),
                  // Pro banner (only show if not pro)
                  if (!purchases.isPro) _buildProBanner(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _handleRestore(BuildContext context, WidgetRef ref) async {
    final restored = await ref.read(purchaseProvider.notifier).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored
              ? 'Purchases restored!'
              : 'No previous purchases found.'),
          backgroundColor: restored ? const Color(0xFF00C853) : null,
        ),
      );
    }
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 16),
      color: AppColors.borderSubtle,
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.satisfied,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionRow(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? AppColors.error : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(icon, size: 18, color: isDestructive ? AppColors.error : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _lockedRow(String label, String subtitle, String badge) {
    final isActive = badge == 'ON';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontSize: 14, fontWeight: FontWeight.w700,
              )),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: [AppColors.satisfied, Color(0xFF00C853)])
                  : const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge, style: const TextStyle(color: Color(0xFF1a0a00), fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildProBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryDark.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upgrade to PRO',
                    style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('No ads \u2022 All packs \u2022 Purist mode',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('PRO',
                style: TextStyle(color: Color(0xFF1a0a00), fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete My Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text(
          'This will permanently delete all your progress, scores, and settings. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Wipe all local data
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              // Anonymize RevenueCat user
              try {
                await Purchases.logOut();
              } catch (_) {}
              // Reset consent
              await ConsentService.instance.resetConsent();
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('All data deleted. Please restart the app.'),
                    backgroundColor: Color(0xFFFF3B30),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
