abstract final class AccountConfig {
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool get hasGoogleConfiguration =>
      googleServerClientId.trim().isNotEmpty;
}
