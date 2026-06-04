import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'purchase_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  bool _initialized = false;
  int _puzzlesSinceLastInterstitial = 0;
  DateTime? _lastInterstitialTime;
  bool _purchaseInProgress = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _consentGiven = false;
  bool get isInitialized => _initialized;

  static String get _interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-XXXXX/XXXXX'; // TODO: replace with production ID
  static String get _rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-XXXXX/XXXXX'; // TODO: replace with production ID

  /// Flag to prevent interstitial during purchase flows (Q2)
  void setPurchaseInProgress(bool value) => _purchaseInProgress = value;

  Future<void> initialize({required bool consentGiven}) async {
    if (_initialized) return;
    _consentGiven = consentGiven;

    await MobileAds.instance.initialize();

    if (!consentGiven) {
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
  /// Will not show if a purchase is in progress (Q2).
  Future<bool> maybeShowInterstitial({required bool isFirstSession}) async {
    if (!_initialized ||
        PurchaseService.instance.isAdFree ||
        isFirstSession ||
        _purchaseInProgress) {
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
  /// Daily cap is enforced by ProgressState.canWatchRewardedAd — check before calling.
  Future<bool> showRewardedAd() async {
    if (!_initialized) return false;
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
      },
    );

    return rewarded;
  }

  bool get hasRewardedAd => _rewardedAd != null;

  AdRequest get _adRequest => AdRequest(
    nonPersonalizedAds: !_consentGiven,
  );

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
