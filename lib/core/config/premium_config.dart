abstract final class PremiumConfig {
  static const bool internalPreviewEnabled = bool.fromEnvironment(
    'TRAILPATH_INTERNAL_PRO',
    defaultValue: false,
  );
}
