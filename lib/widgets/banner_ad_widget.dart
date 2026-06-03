import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../controllers/purchase_controller.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.instance.isInitialized) return;
    final width = MediaQuery.of(context).size.width.truncate();
    _bannerAd = AdService.instance.createBannerAd(
      size: AdSize.getInlineAdaptiveBannerAdSize(width, 60),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchaseProvider);
    if (purchases.isAdFree || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 60,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
