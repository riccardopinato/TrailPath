abstract interface class ProviderUsageTracker {
  Future<void> record({required String provider, required String capability});
}
