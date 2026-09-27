import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/services/provider_usage_tracker.dart';

class LocalProviderUsageTracker implements ProviderUsageTracker {
  const LocalProviderUsageTracker(this._database);

  final AppDatabase _database;

  @override
  Future<void> record({
    required String provider,
    required String capability,
  }) async {
    final normalizedProvider = _normalize(provider);
    final normalizedCapability = _normalize(capability);
    final baseKey =
        'provider_usage_${normalizedProvider}_$normalizedCapability';
    final currentRaw = await _database.getSetting('${baseKey}_count');
    final current = int.tryParse(currentRaw ?? '') ?? 0;

    await _database.setSetting('${baseKey}_count', '${current + 1}');
    await _database.setSetting(
      '${baseKey}_last_at',
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  String _normalize(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.isEmpty ? 'unknown' : normalized;
  }
}
