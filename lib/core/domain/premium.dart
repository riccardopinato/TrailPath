enum PremiumFeature {
  satelliteMaps,
  hybridMaps,
  advancedSmartTrace,
  advancedOffline,
  advancedStats,
  cloudSync,
  collections,
  routeGenerator,
  slopeLayer,
  weatherAlongRoute,
  terrain3d,
}

enum PremiumPlan { monthly, yearly }

enum PremiumVerificationLevel { none, localStoreReceipt, serverVerified }

class PremiumOffer {
  const PremiumOffer({
    required this.plan,
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
  });

  final PremiumPlan plan;
  final String productId;
  final String title;
  final String description;
  final String price;
}

class PremiumSnapshot {
  const PremiumSnapshot({
    this.isLoading = false,
    this.storeAvailable = false,
    this.isPro = false,
    this.purchasePending = false,
    this.offers = const [],
    this.verificationLevel = PremiumVerificationLevel.none,
    this.error,
  });

  const PremiumSnapshot.initial() : this(isLoading: true);

  final bool isLoading;
  final bool storeAvailable;
  final bool isPro;
  final bool purchasePending;
  final List<PremiumOffer> offers;
  final PremiumVerificationLevel verificationLevel;
  final String? error;

  bool has(PremiumFeature feature) => isPro;

  PremiumOffer? offerFor(PremiumPlan plan) {
    for (final offer in offers) {
      if (offer.plan == plan) {
        return offer;
      }
    }
    return null;
  }

  PremiumSnapshot copyWith({
    bool? isLoading,
    bool? storeAvailable,
    bool? isPro,
    bool? purchasePending,
    List<PremiumOffer>? offers,
    PremiumVerificationLevel? verificationLevel,
    String? error,
    bool clearError = false,
  }) {
    return PremiumSnapshot(
      isLoading: isLoading ?? this.isLoading,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      isPro: isPro ?? this.isPro,
      purchasePending: purchasePending ?? this.purchasePending,
      offers: offers ?? this.offers,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      error: clearError ? null : error ?? this.error,
    );
  }
}
