import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/purchase_controller.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../utils/app_theme.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlan = 1; // 0 = monthly, 1 = annual
  List<Package> _packages = [];
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final packages = await PurchaseService.instance.getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
      });
    }
  }

  Package? get _monthlyPackage => _packages
      .where((p) =>
          p.storeProduct.identifier == PurchaseService.proMonthlyId)
      .firstOrNull;

  Package? get _annualPackage => _packages
      .where((p) =>
          p.storeProduct.identifier == PurchaseService.proAnnualId)
      .firstOrNull;

  Package? get _selectedPackage =>
      _selectedPlan == 0 ? _monthlyPackage : _annualPackage;

  String get _ctaText {
    final pkg = _selectedPackage;
    if (pkg == null) return 'START PRO';
    final intro = pkg.storeProduct.introductoryPrice;
    if (intro != null && intro.price == 0) {
      final periods = intro.periodNumberOfUnits;
      final unit = intro.periodUnit.name.toLowerCase();
      return 'TRY FREE FOR $periods ${unit}S';
    }
    return 'START PRO';
  }

  String get _disclosureText {
    final pkg = _selectedPackage;
    if (pkg == null) return '';
    final price = pkg.storeProduct.priceString;
    final period = _selectedPlan == 0 ? 'month' : 'year';
    return 'Payment of $price/$period will be charged to your Apple ID '
        'or Google account at confirmation. Subscription automatically '
        'renews unless cancelled at least 24 hours before the end of '
        'the current period. Manage subscriptions in your device Settings.';
  }

  Future<void> _handlePurchase() async {
    final pkg = _selectedPackage;
    if (pkg == null || _purchasing) return;

    setState(() => _purchasing = true);
    AdService.instance.setPurchaseInProgress(true);
    final result = await PurchaseService.instance.purchase(pkg);
    AdService.instance.setPurchaseInProgress(false);
    if (mounted) {
      setState(() => _purchasing = false);
      switch (result) {
        case PurchaseResult.success:
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Pixel Logic Pro!'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
        case PurchaseResult.cancelled:
          break; // User cancelled — no action needed
        case PurchaseResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase failed. Please try again.'),
            ),
          );
      }
    }
  }

  Future<void> _handleRestore() async {
    final restored = await ref.read(purchaseProvider.notifier).restorePurchases();
    if (mounted) {
      if (restored) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored!'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = _monthlyPackage?.storeProduct.priceString ?? '\$1.99';
    final annualPrice = _annualPackage?.storeProduct.priceString ?? '\$9.99';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 24),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Hero icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primaryDark.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('\u2B50',
                            style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(bounds),
                        child: Text(
                          'PIXEL LOGIC PRO',
                          style: AppFonts.pixel(
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'The ultimate puzzle experience',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Feature list
                      _buildFeatureRow(Icons.block_rounded, 'No Ads',
                          'Uninterrupted puzzling'),
                      _buildFeatureRow(Icons.lock_open_rounded,
                          'All Packs Unlocked', 'Fantasy, Architecture & more'),
                      _buildFeatureRow(Icons.lightbulb_rounded,
                          'Weekly Hints', 'Free hints every week'),
                      _buildFeatureRow(Icons.shield_rounded, 'Purist Mode',
                          'The ultimate challenge \u2014 no safety net'),
                      const SizedBox(height: 24),
                      // Plan selector
                      _buildPlanCard(
                        index: 0,
                        title: 'Monthly',
                        price: '$monthlyPrice/mo',
                        subtitle: 'Cancel anytime',
                      ),
                      const SizedBox(height: 8),
                      _buildPlanCard(
                        index: 1,
                        title: 'Annual',
                        price: '$annualPrice/yr',
                        subtitle: 'Save 58%',
                        badge: 'BEST VALUE',
                      ),
                      const SizedBox(height: 24),
                      // CTA button
                      GestureDetector(
                        onTap: _purchasing ? null : _handlePurchase,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryDark.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _purchasing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1a0a00),
                                  ),
                                )
                              : Text(
                                  _packages.isEmpty ? 'LOADING...' : _ctaText,
                                  style: AppFonts.pixel(
                                    fontSize: 10,
                                    color: const Color(0xFF1a0a00),
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Auto-renewal disclosure (Apple 3.1.2 requirement)
                      if (_packages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _disclosureText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Restore purchases
                      TextButton(
                        onPressed: _handleRestore,
                        child: const Text(
                          'Restore Purchases',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Terms of Use + Privacy Policy links (Apple 3.1.2 requirement)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse(
                                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/')),
                            child: const Text(
                              'Terms of Use',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Text(' · ',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 9)),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse(
                                'https://freelancer-landing-page.web.app/privacy')),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.check_rounded, color: AppColors.satisfied, size: 18),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String subtitle,
    String? badge,
  }) {
    final selected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio dot
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                  color: selected ? AppColors.primary : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                )),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge,
                    style: const TextStyle(
                        color: Color(0xFF1a0a00),
                        fontSize: 7,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
