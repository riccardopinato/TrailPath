import 'package:trail_path/core/domain/premium.dart';

abstract interface class PremiumEngine {
  Stream<PremiumSnapshot> get snapshots;

  Future<PremiumSnapshot> initialize();

  Future<void> purchase(PremiumPlan plan);

  Future<void> restore();

  Future<void> dispose();
}
