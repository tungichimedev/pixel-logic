import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  static PurchaseService get instance => _instance;
  PurchaseService._();

  bool _initialized = false;

  // RevenueCat API keys — replace with your actual keys
  static const _iosApiKey = 'appl_XXXXX'; // TODO: replace
  static const _androidApiKey = 'goog_XXXXX'; // TODO: replace

  // Entitlement IDs (configured in RevenueCat dashboard)
  static const _proEntitlement = 'pro';
  static const _removeAdsEntitlement = 'remove_ads';

  // Product IDs
  static const proMonthlyId = 'pixellogic_pro_monthly'; // $1.99/mo
  static const proAnnualId = 'pixellogic_pro_annual'; // $9.99/yr
  static const removeAdsId = 'pixellogic_remove_ads'; // $2.99 one-time
  static const hintPackId = 'pixellogic_hint_pack_10'; // $1.99

  // Current state
  bool _isPro = false;
  bool _isAdFree = false;
  bool _configured = false; // true only if Purchases.configure() succeeded
  final _stateController = StreamController<void>.broadcast();

  bool get isPro => _isPro;
  bool get isAdFree => _isAdFree || _isPro;
  Stream<void> get onStateChanged => _stateController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosApiKey
        : _androidApiKey;

    // Skip RevenueCat if using placeholder keys
    if (apiKey.contains('XXXXX')) {
      debugPrint('RevenueCat skipped — placeholder API key detected');
      _initialized = true;
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;

      Purchases.addCustomerInfoUpdateListener((info) {
        _updateEntitlements(info);
      });

      final info = await Purchases.getCustomerInfo();
      _updateEntitlements(info);
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
    }

    _initialized = true;
  }

  void _updateEntitlements(CustomerInfo info) {
    _isPro = info.entitlements.active.containsKey(_proEntitlement);
    _isAdFree = _isPro ||
        info.entitlements.active.containsKey(_removeAdsEntitlement);
    _stateController.add(null);
  }

  /// Get available packages for the paywall
  Future<List<Package>> getOfferings() async {
    if (!_configured) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return [];
    }
  }

  /// Purchase a package. Returns a result enum.
  Future<PurchaseResult> purchase(Package package) async {
    if (!_configured) return PurchaseResult.error;
    try {
      final result = await Purchases.purchasePackage(package);
      _updateEntitlements(result);
      return PurchaseResult.success;
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      debugPrint('Purchase error: ${e.code} ${e.message}');
      return PurchaseResult.error;
    } catch (e) {
      debugPrint('Purchase unexpected error: $e');
      return PurchaseResult.error;
    }
  }

  /// Purchase by product ID (for hint packs and non-sub products)
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_configured) return PurchaseResult.error;
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      final pkg = packages.where((p) => p.storeProduct.identifier == productId).firstOrNull;
      if (pkg != null) {
        return purchase(pkg);
      }
      // Fallback: direct product purchase
      final product = await Purchases.getProducts([productId]);
      if (product.isNotEmpty) {
        final result = await Purchases.purchaseStoreProduct(product.first);
        _updateEntitlements(result);
        return PurchaseResult.success;
      }
      return PurchaseResult.error;
    } catch (e) {
      debugPrint('Purchase product error: $e');
      return PurchaseResult.error;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      _updateEntitlements(info);
      return _isPro || _isAdFree;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  void dispose() {
    _stateController.close();
  }
}

enum PurchaseResult { success, cancelled, error }
