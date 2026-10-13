import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/premium.dart';
import 'package:trail_path/core/services/premium_engine.dart';
import 'package:trail_path/infrastructure/premium/play_billing_premium_engine.dart';

final premiumEngineProvider = Provider<PremiumEngine>((ref) {
  final engine = PlayBillingPremiumEngine();
  ref.onDispose(() {
    unawaited(engine.dispose());
  });
  return engine;
});

final premiumControllerProvider =
    NotifierProvider<PremiumController, PremiumSnapshot>(PremiumController.new);

class PremiumController extends Notifier<PremiumSnapshot> {
  StreamSubscription<PremiumSnapshot>? _subscription;
  late PremiumEngine _engine;

  @override
  PremiumSnapshot build() {
    _engine = ref.watch(premiumEngineProvider);
    _subscription = _engine.snapshots.listen((snapshot) {
      if (ref.mounted) {
        state = snapshot;
      }
    });
    ref.onDispose(() {
      unawaited(_subscription?.cancel() ?? Future<void>.value());
    });
    unawaited(_initialize());
    return const PremiumSnapshot.initial();
  }

  Future<void> _initialize() async {
    final snapshot = await _engine.initialize();
    if (ref.mounted) {
      state = snapshot;
    }
  }

  Future<void> purchase(PremiumPlan plan) => _engine.purchase(plan);

  Future<void> restore() => _engine.restore();
}
