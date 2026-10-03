import 'package:flutter/material.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';

class CandidateSelectionCard extends StatelessWidget {
  const CandidateSelectionCard({
    super.key,
    required this.strings,
    required this.point,
    required this.label,
    required this.canUseCurrentLocation,
    required this.pointCount,
    required this.onStart,
    required this.onDestination,
    required this.onWaypoint,
    required this.onCancel,
  });

  final AppLocalizations strings;
  final GeoPoint point;
  final String? label;
  final bool canUseCurrentLocation;
  final int pointCount;
  final VoidCallback onStart;
  final VoidCallback onDestination;
  final VoidCallback onWaypoint;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSetDestination = pointCount > 0 || canUseCurrentLocation;

    return Material(
      color: scheme.surface.withValues(alpha: 0.98),
      elevation: 8,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.place_rounded, color: scheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label ?? strings.pointPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${point.latitude.toStringAsFixed(5)}, '
                        '${point.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.cancel,
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.trip_origin_rounded, size: 18),
                  label: Text(strings.startHere),
                ),
                if (pointCount >= 2)
                  OutlinedButton.icon(
                    onPressed: onWaypoint,
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: Text(strings.addWaypoint),
                  ),
                FilledButton.icon(
                  onPressed: canSetDestination ? onDestination : null,
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: Text(strings.setDestination),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
