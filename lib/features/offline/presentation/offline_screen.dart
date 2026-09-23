import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_providers.dart';

class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  late Future<List<OfflineRegion>> _regionsFuture;

  @override
  void initState() {
    super.initState();
    _regionsFuture = _loadRegions();
  }

  Future<List<OfflineRegion>> _loadRegions() async {
    final manager = ref.read(offlineMapManagerProvider);
    final regions = await manager.listRegions();
    final completeIds = regions
        .where((region) => region.isComplete)
        .map((region) => region.id)
        .toSet();
    final database = ref.read(appDatabaseProvider);
    final routes = await database.listSavedRoutes();

    for (final route in routes) {
      final actualReady = completeIds.contains(route.id);
      if (route.isOfflineReady != actualReady) {
        await database.setSavedRouteOfflineReady(
          route.id,
          isReady: actualReady,
        );
      }
    }

    return regions;
  }

  Future<void> _refresh() async {
    final future = _loadRegions();
    setState(() => _regionsFuture = future);
    await future;
  }

  Future<void> _deleteRegion(OfflineRegion region) async {
    final strings = AppLocalizations.of(context);
    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteOfflineMap),
        content: Text(region.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await manager.delete(region.id);
    await database.setSavedRouteOfflineReady(region.id, isReady: false);
    await _refresh();
  }

  Future<void> _clearCache() async {
    final strings = AppLocalizations.of(context);
    await ref.read(offlineMapManagerProvider).clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.cacheCleared)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.offlineMaps,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              strings.offlineHint,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<OfflineRegion>>(
                future: _regionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _OfflineMessage(
                      icon: Icons.cloud_off_rounded,
                      title: strings.offlineFailed,
                      message: snapshot.error.toString(),
                    );
                  }

                  final regions = snapshot.data ?? const <OfflineRegion>[];
                  final usedBytes = regions.fold<int>(
                    0,
                    (total, region) => total + region.downloadedBytes,
                  );

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _StorageCard(
                          title: strings.offlineStorage,
                          usedLabel: strings.storageUsed,
                          usedBytes: usedBytes,
                          clearLabel: strings.clearMapCache,
                          onClear: _clearCache,
                        ),
                        const SizedBox(height: 14),
                        if (regions.isEmpty)
                          _OfflineMessage(
                            icon: Icons.download_for_offline_outlined,
                            title: strings.noOfflineMaps,
                            message: strings.noOfflineMapsHint,
                          )
                        else
                          for (final region in regions) ...[
                            _RegionCard(
                              region: region,
                              readyLabel: strings.offlineReady,
                              downloadingLabel: strings.downloadingOffline,
                              onDelete: () => _deleteRegion(region),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.title,
    required this.usedLabel,
    required this.usedBytes,
    required this.clearLabel,
    required this.onClear,
  });

  final String title;
  final String usedLabel;
  final int usedBytes;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sd_storage_outlined,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$usedLabel · ${_formatBytes(usedBytes)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(clearLabel),
          ),
        ],
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.readyLabel,
    required this.downloadingLabel,
    required this.onDelete,
  });

  final OfflineRegion region;
  final String readyLabel;
  final String downloadingLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = region.isComplete ? 1.0 : region.progress;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: region.isComplete
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                region.isComplete
                    ? Icons.offline_pin_rounded
                    : Icons.downloading_rounded,
                color: region.isComplete
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${region.isComplete ? readyLabel : downloadingLabel} · '
                    '${_formatBytes(region.downloadedBytes)}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!region.isComplete) ...[
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineMessage extends StatelessWidget {
  const _OfflineMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kib = bytes / 1024;
  if (kib < 1024) {
    return '${kib.toStringAsFixed(kib >= 100 ? 0 : 1)} KB';
  }
  final mib = kib / 1024;
  if (mib < 1024) {
    return '${mib.toStringAsFixed(mib >= 100 ? 0 : 1)} MB';
  }
  final gib = mib / 1024;
  return '${gib.toStringAsFixed(2)} GB';
}
