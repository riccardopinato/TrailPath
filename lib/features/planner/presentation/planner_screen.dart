import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trail_path/app/theme/app_theme.dart';
import 'package:trail_path/core/localization/app_localizations.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [
                        Color(0xFF17261D),
                        Color(0xFF1C3325),
                        Color(0xFF15241C),
                      ]
                    : const [
                        Color(0xFFE8F0E3),
                        Color(0xFFD9E6D4),
                        Color(0xFFEDE9D7),
                      ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TerrainPainter(dark: dark),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xD91A241E)
                            : const Color(0xEFFFFFFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.terrain, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'TrailPath',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _MapActionButton(
                      icon: Icons.layers_outlined,
                      dark: dark,
                    ),
                    const SizedBox(width: 8),
                    _MapActionButton(
                      icon: Icons.my_location,
                      dark: dark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xEB172019)
                        : const Color(0xF5FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.searchPlace,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _PlannerCard(strings: strings),
          ),
        ),
      ],
    );
  }
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.createRoute,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v0.1',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            strings.tapMapHint,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: strings.distance,
                  value: '0.0 km',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: strings.ascent,
                  value: '+0 m',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: strings.duration,
                  value: '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 17,
                color: scheme.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.foundationReady,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.dark,
  });

  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: dark ? const Color(0xD91A241E) : const Color(0xEFFFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20),
    );
  }
}

class _TerrainPainter extends CustomPainter {
  const _TerrainPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final contourPaint = Paint()
      ..color = (dark ? Colors.white : AppTheme.forest)
          .withValues(alpha: dark ? 0.055 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var index = 0; index < 9; index++) {
      final y = size.height * (0.1 + index * 0.105);
      final amplitude = 18.0 + index * 2.3;
      final path = Path()..moveTo(-20, y);

      for (double x = -20; x <= size.width + 20; x += 24) {
        final wave = math.sin((x / 72) + index * 0.65) * amplitude;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, contourPaint);
    }

    final trailPaint = Paint()
      ..color = (dark ? const Color(0xFF91C89E) : AppTheme.forest)
          .withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final trail = Path()
      ..moveTo(size.width * 0.16, size.height * 0.66)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.54,
        size.width * 0.43,
        size.height * 0.63,
        size.width * 0.51,
        size.height * 0.47,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.28,
        size.width * 0.76,
        size.height * 0.43,
        size.width * 0.85,
        size.height * 0.25,
      );

    canvas.drawPath(trail, trailPaint);
  }

  @override
  bool shouldRepaint(covariant _TerrainPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
