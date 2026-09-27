import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/cloud_sync.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/localization/measurement_formatter.dart';
import 'package:trail_path/features/outdoor/presentation/outdoor_screen.dart';
import 'package:trail_path/features/pro/application/premium_controller.dart';
import 'package:trail_path/features/pro/presentation/pro_paywall.dart';
import 'package:trail_path/features/profile/application/account_controller.dart';
import 'package:trail_path/features/profile/application/cloud_sync_controller.dart';
import 'package:trail_path/features/profile/presentation/personal_stats_screen.dart';
import 'package:trail_path/features/routes/presentation/route_collections_screen.dart';
import 'package:trail_path/features/routes/presentation/route_intelligence_screen.dart';
import 'package:trail_path/features/settings/presentation/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final premium = ref.watch(premiumControllerProvider);
    final account = ref.watch(accountControllerProvider);
    final cloud = ref.watch(cloudSyncControllerProvider);
    final routes = ref.watch(savedRoutesProvider);
    final activities = ref.watch(completedActivitiesProvider);

    final routeCount = routes.asData?.value.length ?? 0;
    final completed = activities.asData?.value ?? const <Activity>[];
    final totalDistance = completed.fold<double>(
      0,
      (sum, activity) => sum + activity.distanceMeters,
    );
    final totalAscent = completed.fold<double>(
      0,
      (sum, activity) => sum + activity.ascentMeters,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text(
            strings.profile,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const _AccountCard(),
          const SizedBox(height: 12),
          _ProCard(
            isPro: premium.isPro,
            onTap: () => showTrailPathProPaywall(context, ref),
          ),
          const SizedBox(height: 16),
          Text(
            strings.activitySummary,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_walk_rounded,
                  value: completed.length.toString(),
                  label: strings.activities,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.route_rounded,
                  value: context.formatDistance(totalDistance),
                  label: strings.totalDistance,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  value: context.formatElevation(totalAscent, signed: true),
                  label: strings.totalAscent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatCard(
            icon: Icons.bookmark_rounded,
            value: routeCount.toString(),
            label: strings.savedRoutesCount,
          ),
          const SizedBox(height: 18),
          _ActionCard(
            icon: Icons.landscape_rounded,
            title: strings.outdoorTools,
            subtitle: strings.outdoorHint,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: OutdoorScreen()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.settings_outlined,
            title: strings.settings,
            subtitle: strings.preferences,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.auto_awesome_rounded,
            title: strings.routeLab,
            subtitle: strings.routeLabHint,
            onTap: () => _openProFeature(
              context,
              ref,
              premium.isPro,
              const RouteIntelligenceScreen(),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.folder_copy_outlined,
            title: strings.routeCollections,
            subtitle: strings.routeCollectionsHint,
            onTap: () => _openProFeature(
              context,
              ref,
              premium.isPro,
              const RouteCollectionsScreen(),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.insights_rounded,
            title: strings.personalStats,
            subtitle: strings.personalStatsHint,
            onTap: () => _openProFeature(
              context,
              ref,
              premium.isPro,
              const PersonalStatsScreen(),
            ),
          ),
          const SizedBox(height: 10),
          _CloudSyncCard(
            snapshot: cloud,
            isPro: premium.isPro,
            isSignedIn: account.isSignedIn,
            onTap: () async {
              if (!premium.isPro) {
                await showTrailPathProPaywall(context, ref);
                return;
              }
              if (!account.isSignedIn) {
                await ref.read(accountControllerProvider.notifier).signIn();
                return;
              }
              await ref.read(cloudSyncControllerProvider.notifier).syncNow();
            },
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(accountControllerProvider);
    final controller = ref.read(accountControllerProvider.notifier);
    final profile = state.profile;
    final photoUrl = profile?.photoUrl;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
              child: photoUrl == null
                  ? Icon(
                      profile == null
                          ? Icons.person_outline_rounded
                          : Icons.person_rounded,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName?.trim().isNotEmpty == true
                        ? profile!.displayName!
                        : profile?.email ?? strings.googleAccount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile?.email ??
                        (state.isConfigured
                            ? strings.accountOptional
                            : strings.accountNotConfigured),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (state.isLoading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            else if (profile == null)
              FilledButton.tonal(
                onPressed: state.isConfigured
                    ? () => unawaited(controller.signIn())
                    : null,
                child: Text(strings.signInGoogle),
              )
            else
              IconButton(
                tooltip: strings.signOut,
                onPressed: () => unawaited(_signOutAll(ref, controller)),
                icon: const Icon(Icons.logout_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _CloudSyncCard extends StatelessWidget {
  const _CloudSyncCard({
    required this.snapshot,
    required this.isPro,
    required this.isSignedIn,
    required this.onTap,
  });

  final CloudSyncSnapshot snapshot;
  final bool isPro;
  final bool isSignedIn;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final configured = snapshot.isConfigured;
    final busy = snapshot.isBusy;
    final lastSync = snapshot.lastSyncedAt;
    final pending = snapshot.pendingChanges;

    late final String subtitle;
    if (!configured) {
      subtitle = strings.syncUnavailable;
    } else if (!isPro) {
      subtitle = strings.syncRequiresPro;
    } else if (!isSignedIn) {
      subtitle = strings.syncRequiresAccount;
    } else if (busy) {
      subtitle = strings.syncing;
    } else if (snapshot.error != null) {
      subtitle = strings.syncError;
    } else if (lastSync != null) {
      subtitle =
          '${strings.syncLast}: ${_formatSyncTime(lastSync)} · ${strings.syncPending}: $pending';
    } else {
      subtitle = strings.syncReady;
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        leading: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_sync_outlined),
        title: Text(
          strings.cloudSync,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: configured
            ? const Icon(Icons.chevron_right_rounded)
            : const Icon(Icons.cloud_off_outlined),
        onTap: configured && !busy ? () => unawaited(onTap()) : null,
      ),
    );
  }
}

Future<void> _openProFeature(
  BuildContext context,
  WidgetRef ref,
  bool isPro,
  Widget screen,
) async {
  if (!isPro) {
    await showTrailPathProPaywall(context, ref);
    return;
  }
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));
}

Future<void> _signOutAll(
  WidgetRef ref,
  AccountController accountController,
) async {
  await ref.read(cloudSyncControllerProvider.notifier).signOut();
  await accountController.signOut();
}

String _formatSyncTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month} $hour:$minute';
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.isPro, required this.onTap});

  final bool isPro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: scheme.onPrimaryContainer,
                size: 30,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.trailPathPro,
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro ? strings.proActive : strings.proSubtitle,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? const Icon(Icons.lock_clock_outlined)
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

