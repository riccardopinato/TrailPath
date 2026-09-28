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

  static bool get hasServerVerification =>
      serverVerificationUrl.trim().isNotEmpty;
}
