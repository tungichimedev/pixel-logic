import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase_service.dart';

class PurchaseState {
  final bool isPro;
  final bool isAdFree;
  final bool isLoading;

  const PurchaseState({
    this.isPro = false,
    this.isAdFree = false,
    this.isLoading = false,
  });

  PurchaseState copyWith({bool? isPro, bool? isAdFree, bool? isLoading}) =>
      PurchaseState(
        isPro: isPro ?? this.isPro,
        isAdFree: isAdFree ?? this.isAdFree,
        isLoading: isLoading ?? this.isLoading,
      );
}

class PurchaseController extends Notifier<PurchaseState> {
  StreamSubscription? _sub;

  @override
  PurchaseState build() {
    final service = PurchaseService.instance;
    _sub?.cancel();
    _sub = service.onStateChanged.listen((_) {
      state = state.copyWith(
        isPro: service.isPro,
        isAdFree: service.isAdFree,
      );
    });
    ref.onDispose(() => _sub?.cancel());
    return PurchaseState(
      isPro: service.isPro,
      isAdFree: service.isAdFree,
    );
  }

  Future<bool> restorePurchases() async {
    state = state.copyWith(isLoading: true);
    final restored = await PurchaseService.instance.restorePurchases();
    state = state.copyWith(isLoading: false);
    return restored;
  }
}

final purchaseProvider =
    NotifierProvider<PurchaseController, PurchaseState>(PurchaseController.new);
