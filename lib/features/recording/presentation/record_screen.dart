import 'package:flutter/material.dart';
import 'package:trail_path/core/localization/app_localizations.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.record,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              strings.readyToRecord,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _RecordingMetric(
                      value: '00:00:00',
                      label: 'TIME',
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _RecordingMetric(
                          value: '0.00',
                          label: 'KM',
                          compact: true,
                        ),
                        _RecordingMetric(
                          value: '+0',
                          label: 'M ASCENT',
                          compact: true,
                        ),
                        _RecordingMetric(
                          value: '--',
                          label: 'PACE',
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 44),
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(strings.startRecording),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(210, 58),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GPS engine · v0.2',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingMetric extends StatelessWidget {
  const _RecordingMetric({
    required this.value,
    required this.label,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: compact ? 25 : 42,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? -0.8 : -1.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}
