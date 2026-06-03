import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'purchase_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  bool _initialized = false;
  int _puzzlesSinceLastInterstitial = 0;
  int _rewardedAdsThisSession = 0;
  DateTime? _lastInterstitialTime;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  bool _consentGiven = false;
  bool get isInitialized => _initialized;

  // Test ad unit IDs (debug) vs production IDs (release)
  static String get _bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // test
      : 'ca-app-pub-XXXXX/XXXXX'; // TODO: replace with production ID
  static String get _interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712' // test
      : 'ca-app-pub-XXXXX/XXXXX'; // TODO: replace with production ID
  static String get _rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917' // test
      : 'ca-app-pub-XXXXX/XXXXX'; // TODO: replace with production ID

  Future<void> initialize({required bool consentGiven}) async {
    if (_initialized) return;
    _consentGiven = consentGiven;

    await MobileAds.instance.initialize();

    if (!consentGiven) {
      // Non-personalized ads
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        ),
      );
    }

    _initialized = true;
    _preloadInterstitial();
    _preloadRewarded();
  }

  // --- Banner ---

  BannerAd? createBannerAd({required AdSize size}) {
    if (!_initialized || PurchaseService.instance.isAdFree) return null;

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: _adRequest,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
    return _bannerAd;
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // --- Interstitial ---

  void _preloadInterstitial() {
    if (PurchaseService.instance.isAdFree) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: _adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: ${error.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Call after puzzle completion. Shows interstitial every 4th puzzle,
  /// with 3-minute minimum gap. Skips on first session.
  Future<bool> maybeShowInterstitial({required bool isFirstSession}) async {
    if (!_initialized || PurchaseService.instance.isAdFree || isFirstSession) {
      return false;
    }

    _puzzlesSinceLastInterstitial++;

    if (_puzzlesSinceLastInterstitial < 4) return false;

    // 3-minute frequency cap
    if (_lastInterstitialTime != null &&
        DateTime.now().difference(_lastInterstitialTime!).inSeconds < 180) {
      return false;
    }

    if (_interstitialAd == null) {
      _preloadInterstitial();
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitial();
      },
    );

    await _interstitialAd!.show();
    _puzzlesSinceLastInterstitial = 0;
    _lastInterstitialTime = DateTime.now();
    return true;
  }

  // --- Rewarded ---

  void _preloadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: _adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed to load: ${error.message}');
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show a rewarded ad. Returns true if reward was earned.
  /// Max 2 rewarded ads per session.
  Future<bool> showRewardedAd() async {
    if (!_initialized) return false;
    if (_rewardedAdsThisSession >= 2) return false;
    if (_rewardedAd == null) {
      _preloadRewarded();
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        _rewardedAdsThisSession++;
      },
    );

    return rewarded;
  }

  bool get hasRewardedAd => _rewardedAd != null && _rewardedAdsThisSession < 2;

  AdRequest get _adRequest => AdRequest(
    nonPersonalizedAds: !_consentGiven,
  );

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
