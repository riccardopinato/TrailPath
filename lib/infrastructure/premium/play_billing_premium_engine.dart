import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:trail_path/core/config/premium_config.dart';
import 'package:trail_path/core/domain/premium.dart';
import 'package:trail_path/core/services/premium_engine.dart';

class PlayBillingPremiumEngine implements PremiumEngine {
  PlayBillingPremiumEngine({
    InAppPurchase? store,
    http.Client? verificationClient,
  }) : _store = store ?? InAppPurchase.instance,
       _verificationClient = verificationClient ?? http.Client(),
       _ownsVerificationClient = verificationClient == null;

  static const String monthlyProductId = 'trailpath_pro_monthly';
  static const String yearlyProductId = 'trailpath_pro_yearly';

  static const Set<String> _productIds = {monthlyProductId, yearlyProductId};

  final InAppPurchase _store;
  final http.Client _verificationClient;
  final bool _ownsVerificationClient;
  final StreamController<PremiumSnapshot> _controller =
      StreamController<PremiumSnapshot>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  PremiumSnapshot _snapshot = const PremiumSnapshot.initial();
  final Map<String, ProductDetails> _products = {};
  bool _initialized = false;

  @override
  Stream<PremiumSnapshot> get snapshots => _controller.stream;

  @override
  Future<PremiumSnapshot> initialize() async {
    if (_initialized) {
      return _snapshot;
    }
    _initialized = true;

    if (PremiumConfig.internalPreviewEnabled) {
      _emit(
        const PremiumSnapshot(
          isPro: true,
          verificationLevel: PremiumVerificationLevel.internalPreview,
        ),
      );
      return _snapshot;
    }

    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        _emit(
          _snapshot.copyWith(
            isLoading: false,
            purchasePending: false,
            error: error.toString(),
          ),
        );
      },
    );

    try {
      final available = await _store.isAvailable();
      if (!available) {
        _emit(
          _snapshot.copyWith(
            isLoading: false,
            storeAvailable: false,
            clearError: true,
          ),
        );
        return _snapshot;
      }

      final response = await _store.queryProductDetails(_productIds);
      _products
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );

      final offers = <PremiumOffer>[
        for (final product in response.productDetails)
          if (_planForProduct(product.id) case final PremiumPlan plan)
            PremiumOffer(
              plan: plan,
              productId: product.id,
              title: product.title,
              description: product.description,
              price: product.price,
            ),
      ]..sort((a, b) => a.plan.index.compareTo(b.plan.index));

      final missing = response.notFoundIDs;
      _emit(
        _snapshot.copyWith(
          isLoading: false,
          storeAvailable: true,
          offers: List<PremiumOffer>.unmodifiable(offers),
          error: missing.isEmpty
              ? null
              : 'Missing Play products: ${missing.join(', ')}',
          clearError: missing.isEmpty,
        ),
      );

      // Restore owned subscriptions silently so a returning user regains Pro.
      unawaited(_safeRestore());
      return _snapshot;
    } on Object catch (error) {
      _emit(
        _snapshot.copyWith(
          isLoading: false,
          storeAvailable: false,
          error: error.toString(),
        ),
      );
      return _snapshot;
    }
  }

  @override
  Future<void> purchase(PremiumPlan plan) async {
    final productId = _productIdForPlan(plan);
    final product = _products[productId];
    if (!_snapshot.storeAvailable || product == null) {
      _emit(
        _snapshot.copyWith(
          purchasePending: false,
          error: 'Premium product is not available from Google Play.',
        ),
      );
      return;
    }

    _emit(_snapshot.copyWith(purchasePending: true, clearError: true));
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _emit(
          _snapshot.copyWith(
            purchasePending: false,
            error: 'Google Play did not start the purchase flow.',
          ),
        );
      }
    } on Object catch (error) {
      _emit(
        _snapshot.copyWith(purchasePending: false, error: error.toString()),
      );
    }
  }

  @override
  Future<void> restore() async {
    if (!_snapshot.storeAvailable) {
      return;
    }
    _emit(_snapshot.copyWith(purchasePending: true, clearError: true));
    await _safeRestore();
  }

  Future<void> _safeRestore() async {
    try {
      await _store.restorePurchases();
      _emit(_snapshot.copyWith(purchasePending: false, clearError: true));
    } on Object catch (error) {
      _emit(
        _snapshot.copyWith(purchasePending: false, error: error.toString()),
      );
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    var pro = _snapshot.isPro;
    var verification = _snapshot.verificationLevel;
    var pending = false;
    String? error;

    for (final purchase in purchases) {
      final plan = _planForProduct(purchase.productID);
      if (plan == null) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          pending = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final valid = _hasLocalStoreReceipt(purchase);
          if (!valid) {
            error = 'Purchase receipt could not be validated locally.';
            break;
          }

          if (PremiumConfig.hasServerVerification) {
            final serverValid = await _verifyWithServer(purchase);
            if (serverValid) {
              pro = true;
              verification = PremiumVerificationLevel.serverVerified;
            } else {
              error = 'Purchase could not be verified by the server.';
            }
          } else if (PremiumConfig.requireServerVerification) {
            error = 'Server purchase verification is not configured.';
          } else {
            pro = true;
            verification = PremiumVerificationLevel.localStoreReceipt;
          }
        case PurchaseStatus.error:
          error = purchase.error?.message ?? 'Google Play purchase failed.';
        case PurchaseStatus.canceled:
          pending = false;
      }

      if (purchase.pendingCompletePurchase &&
          purchase.status != PurchaseStatus.pending) {
        try {
          await _store.completePurchase(purchase);
        } on Object catch (completeError) {
          error ??= completeError.toString();
        }
      }
    }

    _emit(
      _snapshot.copyWith(
        isLoading: false,
        isPro: pro,
        purchasePending: pending,
        verificationLevel: verification,
        error: error,
        clearError: error == null,
      ),
    );
  }

  Future<bool> _verifyWithServer(PurchaseDetails purchase) async {
    try {
      final response = await _verificationClient
          .post(
            Uri.parse(PremiumConfig.serverVerificationUrl),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'platform': 'google_play',
              'productId': purchase.productID,
              'purchaseToken': purchase.verificationData.serverVerificationData,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return false;
      }
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['valid'] == true;
    } on Object {
      return false;
    }
  }

  bool _hasLocalStoreReceipt(PurchaseDetails purchase) {
    if (!_productIds.contains(purchase.productID)) {
      return false;
    }
    return purchase.verificationData.serverVerificationData.trim().isNotEmpty;
  }

  PremiumPlan? _planForProduct(String productId) {
    return switch (productId) {
      monthlyProductId => PremiumPlan.monthly,
      yearlyProductId => PremiumPlan.yearly,
      _ => null,
    };
  }

  String _productIdForPlan(PremiumPlan plan) {
    return switch (plan) {
      PremiumPlan.monthly => monthlyProductId,
      PremiumPlan.yearly => yearlyProductId,
    };
  }

  void _emit(PremiumSnapshot next) {
    _snapshot = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
    if (_ownsVerificationClient) {
      _verificationClient.close();
    }
  }
}
