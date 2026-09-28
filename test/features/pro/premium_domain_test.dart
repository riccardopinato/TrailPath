import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/premium.dart';

void main() {
  test('PremiumSnapshot gates all premium features behind Pro', () {
    const free = PremiumSnapshot();
    const pro = PremiumSnapshot(
      isPro: true,
      verificationLevel: PremiumVerificationLevel.localStoreReceipt,
    );

    for (final feature in PremiumFeature.values) {
      expect(free.has(feature), isFalse);
      expect(pro.has(feature), isTrue);
    }
  });

  test('Premium issue classification distinguishes configuration failures', () {
    const storeUnavailable = PremiumSnapshot();
    const missingProducts = PremiumSnapshot(
      storeAvailable: true,
      error: 'Missing Play products: trailpath_pro_monthly',
    );
    const verificationUnavailable = PremiumSnapshot(
      storeAvailable: true,
      error: 'Server purchase verification is not configured.',
    );
    const purchaseFailure = PremiumSnapshot(
      storeAvailable: true,
      error: 'Google Play purchase failed.',
    );

    expect(storeUnavailable.issue, PremiumIssue.storeUnavailable);
    expect(missingProducts.issue, PremiumIssue.productsUnavailable);
    expect(
      verificationUnavailable.issue,
      PremiumIssue.verificationUnavailable,
    );
    expect(purchaseFailure.issue, PremiumIssue.purchaseFailed);
  });

  test('Premium offers resolve by plan', () {
    const monthly = PremiumOffer(
      plan: PremiumPlan.monthly,
      productId: 'monthly',
      title: 'Monthly',
      description: 'Monthly Pro',
      price: '€2.99',
    );
    const snapshot = PremiumSnapshot(offers: [monthly]);

    expect(snapshot.offerFor(PremiumPlan.monthly), same(monthly));
    expect(snapshot.offerFor(PremiumPlan.yearly), isNull);
  });
}
