import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../controllers/purchase_controller.dart';
import '../services/ad_service.dart';
import '../services/consent_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _adLoaded = false;

  static String get _bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-XXXXX/XXXXX'; // TODO: replace with production ID

  @override
  void initState() {
    super.initState();
    // Load ad once in initState, not didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  void _loadAd() {
    if (!AdService.instance.isInitialized || _bannerAd != null) return;

    final width = MediaQuery.of(context).size.width.truncate();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.getInlineAdaptiveBannerAdSize(width, 60),
      request: AdRequest(
        nonPersonalizedAds: !ConsentService.instance.consentGiven,
      ),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchaseProvider);
    if (purchases.isAdFree || _bannerAd == null || !_adLoaded) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 60,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
