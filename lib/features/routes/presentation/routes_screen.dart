import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/navigation/presentation/navigation_screen.dart';
import 'package:trail_path/features/offline/application/offline_downloads_controller.dart';

class RoutesScreen extends ConsumerWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final routes = ref.watch(savedRoutesProvider);
    final activities = ref.watch(completedActivitiesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.routes,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: routes.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, stackTrace) => _RoutesMessage(
                  icon: Icons.error_outline_rounded,
                  title: strings.locationUnavailable,
                  message: error.toString(),
                ),
                data: (routeItems) => activities.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (error, stackTrace) => _RoutesMessage(
                    icon: Icons.error_outline_rounded,
                    title: strings.locationUnavailable,
                    message: error.toString(),
                  ),
                  data: (activityItems) {
                    if (routeItems.isEmpty && activityItems.isEmpty) {
                      return _RoutesMessage(
                        icon: Icons.route_outlined,
                        title: strings.noRoutes,
                        message: strings.noRoutesHint,
                      );
                    }

                    return ListView(
                      children: [
                        Text(
                          strings.yourRoutes,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (routeItems.isEmpty)
                          _InlineEmpty(
                            icon: Icons.route_outlined,
                            text: strings.noRoutes,
                          )
                        else
                          for (final route in routeItems) ...[
                            _RouteCard(
                              route: route,
                              onNavigate: () =>
                                  _openNavigation(context, ref, route),
                              onShare: () =>
                                  _shareRoute(context, ref, route),
                              onDelete: () =>
                                  _deleteRoute(context, ref, route),
                            ),
                            const SizedBox(height: 10),
                          ],
                        const SizedBox(height: 18),
                        Text(
                          strings.yourActivities,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (activityItems.isEmpty)
                          _InlineEmpty(
                            icon: Icons.directions_walk_rounded,
                            text: strings.noActivities,
                          )
                        else
                          for (final activity in activityItems) ...[
                            _ActivityCard(
                              activity: activity,
                              onShare: () =>
                                  _shareActivity(context, ref, activity),
                              onDelete: () =>
                                  _deleteActivity(context, ref, activity),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNavigation(
    BuildContext context,
    WidgetRef ref,
    SavedRoute route,
  ) async {
    final plan = ref.read(appDatabaseProvider).savedRouteToPlan(route);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NavigationScreen(
          routeName: route.name,
          route: plan,
        ),
      ),
    );
  }

  Future<void> _shareRoute(
    BuildContext context,
    WidgetRef ref,
    SavedRoute route,
  ) async {
    final strings = AppLocalizations.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    try {
      final document = ref.read(appDatabaseProvider).savedRouteToGpx(route);
      final xml = await ref.read(gpxServiceProvider).export(document);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(xml)),
              mimeType: 'application/gpx+xml',
            ),
          ],
          fileNameOverrides: [_safeGpxFileName(route.name)],
          title: route.name,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.gpxExportError)),
        );
      }
    }
  }

  Future<void> _shareActivity(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final strings = AppLocalizations.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    try {
      final document = ref.read(appDatabaseProvider).activityToGpx(activity);
      final xml = await ref.read(gpxServiceProvider).export(document);
      final name = activity.name ?? 'TrailPath activity';

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(xml)),
              mimeType: 'application/gpx+xml',
            ),
          ],
          fileNameOverrides: [_safeGpxFileName(name)],
          title: name,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.gpxExportError)),
        );
      }
    }
  }

  Future<void> _deleteRoute(
    BuildContext context,
    WidgetRef ref,
    SavedRoute route,
  ) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteRoute),
        content: Text(route.name),
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

    if (confirmed == true) {
      await ref.read(appDatabaseProvider).deleteSavedRoute(route.id);
    }
  }

  Future<void> _deleteActivity(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteActivity),
        content: Text(activity.name ?? strings.yourActivities),
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

    if (confirmed == true) {
      await ref.read(appDatabaseProvider).discardActivity(activity.id);
    }
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onNavigate,
    required this.onShare,
    required this.onDelete,
  });

  final SavedRoute route;
  final VoidCallback onNavigate;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final duration = Duration(seconds: route.durationSeconds);

    return _BaseCard(
      icon: Icons.route_rounded,
      title: route.name,
      subtitle:
          '${_formatDistance(route.distanceMeters)} · '
          '${_formatDuration(duration)} · '
          '${_profileName(strings, route.profile)}',
      onPrimary: onNavigate,
      primaryTooltip: strings.navigate,
      extraAction: _OfflineRouteAction(route: route),
      onShare: onShare,
      onDelete: onDelete,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.onShare,
    required this.onDelete,
  });

  final Activity activity;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final name = activity.name ?? strings.yourActivities;
    final duration = Duration(seconds: activity.movingSeconds);

    return _BaseCard(
      icon: Icons.directions_walk_rounded,
      title: name,
      subtitle:
          '${_formatDistance(activity.distanceMeters)} · '
          '${_formatDuration(duration)} · '
          '+${activity.ascentMeters.round()} m · '
          '${_profileName(strings, activity.profile)}',
      onShare: onShare,
      onDelete: onDelete,
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onPrimary,
    this.primaryTooltip,
    this.extraAction,
    required this.onShare,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPrimary;
  final String? primaryTooltip;
  final Widget? extraAction;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onPrimary != null)
              IconButton(
                tooltip: primaryTooltip,
                onPressed: onPrimary,
                icon: const Icon(Icons.navigation_rounded),
              ),
            extraAction?,
            PopupMenuButton<String>(
              tooltip: strings.routes,
              onSelected: (value) {
                if (value == 'share') {
                  onShare();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: const Icon(Icons.ios_share_rounded),
                    title: Text(strings.shareGpx),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text(strings.delete),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineRouteAction extends ConsumerWidget {
  const _OfflineRouteAction({required this.route});

  final SavedRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final downloads = ref.watch(offlineDownloadsProvider);
    final active = downloads.isDownloading(route.id);
    final progress = downloads.progress(route.id);

    if (active) {
      return Tooltip(
        message: strings.downloadingOffline,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              value: progress > 0 ? progress : null,
            ),
          ),
        ),
      );
    }

    if (route.isOfflineReady) {
      return IconButton(
        tooltip: strings.offlineReady,
        onPressed: null,
        icon: const Icon(Icons.offline_pin_rounded),
      );
    }

    return IconButton(
      tooltip: strings.downloadOffline,
      onPressed: () => _prepare(context, ref),
      icon: const Icon(Icons.download_for_offline_outlined),
    );
  }

  Future<void> _prepare(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final database = ref.read(appDatabaseProvider);
    try {
      final plan = database.savedRouteToPlan(route);
      final success = await ref
          .read(offlineDownloadsProvider.notifier)
          .prepareRoute(
            routeId: route.id,
            routeName: route.name,
            geometry: plan.geometry,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? strings.offlineReady : strings.offlineFailed,
            ),
          ),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.offlineFailed)),
        );
      }
    }
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutesMessage extends StatelessWidget {
  const _RoutesMessage({
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                size: 42,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}

String _formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '$minutes min';
  }
  final minuteText = minutes.toString().padLeft(2, '0');
  return '$hours h $minuteText';
}

String _profileName(AppLocalizations strings, String profile) {
  return switch (profile) {
    'hiking' => strings.profileHiking,
    'trailRunning' => strings.profileTrailRun,
    'walking' => strings.profileWalking,
    'mountainBike' => strings.profileMtb,
    'cycling' => strings.profileCycling,
    'dogWalk' => strings.profileDogWalk,
    _ => profile,
  };
}

String _safeGpxFileName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[^A-Za-z0-9._ -]+'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return '${cleaned.isEmpty ? 'TrailPath_route' : cleaned}.gpx';
}
