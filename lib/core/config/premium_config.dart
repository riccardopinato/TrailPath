import 'package:flutter/foundation.dart';

abstract final class PremiumConfig {
  static const bool internalPreviewEnabled = bool.fromEnvironment(
    'TRAILPATH_INTERNAL_PRO',
    defaultValue: false,
  );

  static const String serverVerificationUrl = String.fromEnvironment(
    'PREMIUM_VERIFICATION_URL',
  );

  static const bool requireServerVerification = bool.fromEnvironment(
    'TRAILPATH_REQUIRE_SERVER_VERIFICATION',
    defaultValue: false,
  );

  /// Release builds never grant a production Pro entitlement from a local
  /// receipt alone. Debug/profile builds may use local receipts for developer
  /// testing, while dedicated internal-Pro artifacts bypass billing earlier.
  static bool get enforceServerVerification =>
      requireServerVerification || kReleaseMode;

  static bool get hasServerVerification =>
      serverVerificationUrl.trim().isNotEmpty;
}
