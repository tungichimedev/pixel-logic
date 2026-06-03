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
  final _stateController = StreamController<void>.broadcast();

  bool get isPro => _isPro;
  bool get isAdFree => _isAdFree || _isPro;
  Stream<void> get onStateChanged => _stateController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosApiKey
        : _androidApiKey;

    await Purchases.configure(PurchasesConfiguration(apiKey));

    // Listen for purchase updates
    Purchases.addCustomerInfoUpdateListener((info) {
      _updateEntitlements(info);
    });

    // Initial check
    try {
      final info = await Purchases.getCustomerInfo();
      _updateEntitlements(info);
    } catch (e) {
      debugPrint('RevenueCat initial check failed: $e');
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
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return [];
    }
  }

  /// Purchase a package. Returns true on success.
  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      _updateEntitlements(result);
      return true;
    } catch (e) {
      if (e is PurchasesErrorCode) {
        debugPrint('Purchase error: $e');
      }
      return false;
    }
  }

  /// Purchase by product ID (for hint packs and non-sub products)
  Future<bool> purchaseProduct(String productId) async {
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
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase product error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
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
