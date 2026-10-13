import 'package:trail_path/core/config/account_config.dart';
import 'package:trail_path/core/config/cloud_config.dart';
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/config/premium_config.dart';

class ProductionServicesSnapshot {
  const ProductionServicesSnapshot({
    required this.googleSignIn,
    required this.premiumMaps,
    required this.routingProvider,
    required this.cloudSync,
    required this.purchaseVerification,
  });

  final bool googleSignIn;
  final bool premiumMaps;
  final bool routingProvider;
  final bool cloudSync;
  final bool purchaseVerification;

  bool get isReleaseReady =>
      googleSignIn &&
      premiumMaps &&
      routingProvider &&
      cloudSync &&
      purchaseVerification;

  List<String> get missingServices => <String>[
    if (!googleSignIn) 'Google Sign-In',
    if (!premiumMaps) 'MapTiler premium maps',
    if (!routingProvider) 'Dedicated Valhalla routing',
    if (!cloudSync) 'Supabase Cloud Sync',
    if (!purchaseVerification) 'Play purchase server verification',
  ];
}

abstract final class ProductionServicesConfig {
  static ProductionServicesSnapshot get snapshot => ProductionServicesSnapshot(
    googleSignIn: AccountConfig.hasGoogleConfiguration,
    premiumMaps: MapConfig.hasPremiumMapProvider,
    routingProvider: MapConfig.hasDedicatedRoutingProvider,
    cloudSync: CloudConfig.isConfigured,
    purchaseVerification: PremiumConfig.hasServerVerification,
  );
}
