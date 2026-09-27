import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/localization/measurement_formatter.dart';
import 'package:trail_path/features/profile/application/personal_stats.dart';

class PersonalStatsScreen extends ConsumerWidget {
  const PersonalStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final activities = ref.watch(completedActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.personalStats)),
      body: activities.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, stackTrace) =>
            Center(child: Text(strings.statsUnavailable)),
        data: (items) {
          final stats = buildPersonalStats(items);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _HeroStat(
                value: context.formatDistance(stats.totalDistanceMeters),
                label: strings.totalDistance,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _Metric(
                    icon: Icons.directions_walk_rounded,
                    value: stats.activityCount.toString(),
                    label: strings.activities,
                  ),
                  _Metric(
                    icon: Icons.trending_up_rounded,
                    value: context.formatElevation(stats.totalAscentMeters, signed: true),
                    label: strings.totalAscent,
                  ),
                  _Metric(
                    icon: Icons.calendar_view_week_rounded,
                    value: context.formatDistance(stats.last7DaysDistanceMeters),
                    label: strings.last7Days,
                  ),
                  _Metric(
                    icon: Icons.calendar_month_rounded,
                    value: context.formatDistance(stats.last30DaysDistanceMeters),
                    label: strings.last30Days,
                  ),
                  _Metric(
                    icon: Icons.straighten_rounded,
                    value: context.formatDistance(stats.longestActivityMeters),
                    label: strings.longestActivity,
                  ),
                  _Metric(
                    icon: Icons.landscape_rounded,
                    value: context.formatElevation(stats.highestAscentMeters, signed: true),
                    label: strings.highestAscent,
                  ),
                  _Metric(
                    icon: Icons.schedule_rounded,
                    value: _duration(stats.totalMovingTime),
                    label: strings.movingTime,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


String _duration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  return hours > 0
      ? '$hours h ${minutes.toString().padLeft(2, '0')}'
      : '$minutes min';
}
